//
//  GotItViewController.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/21/13.

#import "GotItViewController.h"
#import "GettingStartedConstants.h"
#import "MWI18N.h"
#import "UILabel+ResizeWithAttributes.h"
#import "MockPageViewController.h"
#import "MockBadPhotoViewController.h"
#import "UIView+Debugging.h"

@interface GotItViewController (){
    UITapGestureRecognizer *tapRecognizer_;
    UITapGestureRecognizer *doubleTapRecognizer_;
}

@end

@implementation GotItViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = GETTING_STARTED_BG_COLOR;
    [self.yesButton setTitleColor:GETTING_STARTED_BG_COLOR forState:UIControlStateNormal];
    
    tapRecognizer_ = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
	tapRecognizer_.numberOfTapsRequired = 1;
	[self.view addGestureRecognizer:tapRecognizer_];

	doubleTapRecognizer_ = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap)];
	doubleTapRecognizer_.numberOfTapsRequired = 2;
	[self.view addGestureRecognizer:doubleTapRecognizer_];

    self.gotItLabel.text = [MWMessage forKey:@"getting-started-got-it-label"].text;
    [self.yesButton setTitle:[MWMessage forKey:@"getting-started-yes-button"].text forState:UIControlStateNormal];

    [self.yesButton.titleLabel setFont:[UIFont boldSystemFontOfSize:GETTING_STARTED_HEADING_FONT_SIZE]];

    self.verticalSpaceBetweenLabels.constant = self.view.frame.size.height * GETTING_STARTED_VERTICAL_SPACE_BETWEEN_LABELS;
    self.verticalSpaceBetweenHalves.constant = self.view.frame.size.height * GETTING_STARTED_VERTICAL_SPACE_BETWEEN_HALVES;

    // Widen the labels for iPad
    self.gotItLabelWidth.constant *= GETTING_STARTED_LABEL_WIDTH_MULTIPLIER;

    // Constrain the mock views horizonally. Ensures the scaled animations have sufficient space between them.
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.mockPageContainerView
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1
                                                           constant:(self.view.frame.size.width * GETTING_STARTED_GOTIT_MOCKPAGE_PERCENT_FROM_LEFT)]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.mockBadPhotoContainerView
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1
                                                           constant:-(self.view.frame.size.width * GETTING_STARTED_GOTIT_MOCKBADPHOTO_PERCENT_FROM_RIGHT)]];

	// Scale the animations up for iPad
	CGAffineTransform xf = CGAffineTransformMakeScale(GETTING_STARTED_GOTIT_ANIMATIONS_SCALE, GETTING_STARTED_GOTIT_ANIMATIONS_SCALE);
	self.mockPageContainerView.transform = xf;
	self.mockBadPhotoContainerView.transform = xf;

	// Style attributes for labels
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	paragraphStyle.alignment = NSTextAlignmentCenter;
	paragraphStyle.lineSpacing = GETTING_STARTED_LABEL_LINE_SPACING;
	paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
	
	// Apply styled attributes to label resizing it to fit the newly styled text (regardless of i18n string length!)
	[self.gotItLabel resizeWithAttributes: @{
					 NSFontAttributeName : [UIFont boldSystemFontOfSize:GETTING_STARTED_HEADING_FONT_SIZE],
		   NSParagraphStyleAttributeName : paragraphStyle,
		  NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0f alpha:1.0f]
	 } preferredMaxLayoutWidth:self.gotItLabelWidth.constant];

    // The button should resize properly if its i18n text is large, but it needs some padding around the text, which this provides.
    self.yesButton.contentEdgeInsets = UIEdgeInsetsMake(9.0f, 20.0f, 9.0f, 20.0f);

    //[self.view randomlyColorSubviews];
}

-(void)viewDidAppear:(BOOL)animated
{
    [self drawAttentionToYesButtonWithDelay:GETTING_STARTED_GOTIT_YESBUTTONATTENTION_ANIMATION_DELAY];
}

-(void)handleTap
{
    [self drawAttentionToYesButtonWithDelay:0.0f];
}

-(void)handleDoubleTap
{
    [self dismissModalView];
}

-(void)drawAttentionToYesButtonWithDelay:(float)delay
{
    CABasicAnimation *(^animatePathToValue)(NSString *, NSValue *) = ^(NSString *path, NSValue *toValue){
        CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:path];
        a.fillMode = kCAFillModeForwards;
        a.autoreverses = YES;
        a.duration = 0.13f;
        a.removedOnCompletion = YES;
        [a setBeginTime:CACurrentMediaTime() + delay];
        a.toValue = toValue;
        return a;
    };

    [self.gotItLabel.layer addAnimation:animatePathToValue(@"opacity", @0.5f) forKey:nil];

    CATransform3D xf = CATransform3DMakeScale(1.08f, 1.08f, 1.0f);
    [self.yesButton.layer addAnimation:animatePathToValue(@"transform", [NSValue valueWithCATransform3D:xf]) forKey:nil];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{	// Adjust properties on embedded view's view controller
	// Why a segue? See: http://stackoverflow.com/a/13279703
	
	if ([segue.identifier isEqualToString: @"GotIt_MockPage_Embed"]) {
		MockPageViewController *mockPageVC = (MockPageViewController *) [segue destinationViewController];
		mockPageVC.animationDelay = GETTING_STARTED_GOTIT_MOCKPAGE_ANIMATION_DELAY;
	}else if ([segue.identifier isEqualToString: @"GotIt_MockBadPhoto_Embed"]) {
			MockBadPhotoViewController *mockBadPhotoVC = (MockBadPhotoViewController *) [segue destinationViewController];
			mockBadPhotoVC.animationDelay = GETTING_STARTED_GOTIT_MOCKBADPHOTO_ANIMATION_DELAY;
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissModalView
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissModalView" object:nil userInfo:nil];
}

- (IBAction)yesButtonPushed:(id)sender
{
    [self dismissModalView];
}

@end
