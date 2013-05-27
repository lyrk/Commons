//
//  GotItViewController.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/21/13.

#import "GotItViewController.h"
#import "GettingStartedConstants.h"
#import "MWI18N.h"
#import "UILabel+ResizeWithAttributes.h"
#import "UIView+VerticalSpace.h"
#import "MockPageViewController.h"
#import "MockBadPhotoViewController.h"

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
    
    self.mockPageContainerView.transform = CGAffineTransformMakeScale(0.5, 0.5);
    self.mockBadPhotoContainerView.transform = CGAffineTransformMakeScale(0.5, 0.5);

    tapRecognizer_ = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
	tapRecognizer_.numberOfTapsRequired = 1;
	[self.view addGestureRecognizer:tapRecognizer_];

	doubleTapRecognizer_ = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap)];
	doubleTapRecognizer_.numberOfTapsRequired = 2;
	[self.view addGestureRecognizer:doubleTapRecognizer_];

    self.gotItLabel.text = [MWMessage forKey:@"getting-started-got-it-label"].text;
    [self.yesButton setTitle:[MWMessage forKey:@"getting-started-yes-button"].text forState:UIControlStateNormal];
	
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
	 }];
	
	// Ensure constant spacing around the newly resized labels
	[self.gotItLabel moveBelowView:self.mockBadPhotoContainerView spacing:40.0f];
	[self.yesButton moveBelowView:self.gotItLabel spacing:22.0f];
}

-(void)handleTap
{
    [self drawAttentionToYesButton];
}

-(void)handleDoubleTap
{
    [self dismissModalView];
}

-(void)drawAttentionToYesButton
{
    [UIView animateWithDuration:0.13f
                          delay:0.0f
                        options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         self.gotItLabel.alpha = 0.5f;
                         self.yesButton.transform = CGAffineTransformMakeScale(1.08f, 1.08f);
                     }
                     completion:^(BOOL finished){
                         [UIView animateWithDuration:0.13f
                                               delay:0.0f
                                             options:UIViewAnimationOptionTransitionNone
                                          animations:^{
                                              self.gotItLabel.alpha = 1.0f;
                                              self.yesButton.transform = CGAffineTransformIdentity;
                                          }
                                          completion:^(BOOL finished){
                                          }];
                     }];
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
