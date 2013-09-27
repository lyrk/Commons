//
//  WhatIsCommonsViewController.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/23/13.

#import "WhatIsCommonsViewController.h"
#import "GettingStartedConstants.h"
#import "MWI18N.h"
#import "UILabel+ResizeWithAttributes.h"
#import "UIView+Space.h"
#import "MockPageViewController.h"

@interface WhatIsCommonsViewController ()

@end

@implementation WhatIsCommonsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = GETTING_STARTED_BG_COLOR;
    
	// Scale the animation up for iPad
	CGAffineTransform xf = CGAffineTransformMakeScale(GETTING_STARTED_WHATISCOMMONS_ANIMATION_SCALE, GETTING_STARTED_WHATISCOMMONS_ANIMATION_SCALE);
	self.mockPageContainerView.transform = xf;
	
    self.contributeLabel.text = [MWMessage forKey:@"getting-started-what-is-commons-contribute-label"].text;
    self.imagesLabel.text = [MWMessage forKey:@"getting-started-what-is-commons-images-label"].text;

    self.verticalSpaceBetweenLabels.constant = self.view.frame.size.height * GETTING_STARTED_VERTICAL_SPACE_BETWEEN_LABELS;
    self.verticalSpaceBetweenHalves.constant = self.view.frame.size.height * GETTING_STARTED_VERTICAL_SPACE_BETWEEN_HALVES;

    // Widen the labels for iPad
    self.contributeLabelWidth.constant *= GETTING_STARTED_LABEL_WIDTH_MULTIPLIER;
    self.imagesLabelWidth.constant *= GETTING_STARTED_LABEL_WIDTH_MULTIPLIER;

	// Style attributes for labels
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	paragraphStyle.alignment = NSTextAlignmentCenter;
	paragraphStyle.lineSpacing = GETTING_STARTED_LABEL_LINE_SPACING;
	paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
	
    // Apply styled attributes to label resizing it to fit the newly styled text (regardless of i18n string length!)
    [self.contributeLabel resizeWithAttributes: @{
						  NSFontAttributeName : [UIFont boldSystemFontOfSize:GETTING_STARTED_HEADING_FONT_SIZE],
				NSParagraphStyleAttributeName : paragraphStyle,
			   NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0f alpha:1.0f]
	 } preferredMaxLayoutWidth:self.contributeLabelWidth.constant];

	[self.imagesLabel resizeWithAttributes: @{
					  NSFontAttributeName : [UIFont systemFontOfSize:GETTING_STARTED_SUB_HEADING_FONT_SIZE],
			NSParagraphStyleAttributeName : paragraphStyle,
		   NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0f alpha:0.9f]
	 } preferredMaxLayoutWidth:self.imagesLabelWidth.constant];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{	// Adjust properties on embedded view's view controller
	// Why a segue? See: http://stackoverflow.com/a/13279703
	
	if ([segue.identifier isEqualToString: @"WhatIsCommons_MockPage_Embed"]) {
		MockPageViewController *mockPageVC = (MockPageViewController *) [segue destinationViewController];
		mockPageVC.animationDelay = GETTING_STARTED_WHATISCOMMONS_MOCKPAGE_ANIMATION_DELAY;
		mockPageVC.animationDelayOnce = YES;
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
