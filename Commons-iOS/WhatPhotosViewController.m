//
//  WhatPhotosViewController.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/23/13.

#import "WhatPhotosViewController.h"
#import "GettingStartedConstants.h"
#import "MWI18N.h"
#import "UILabel+ResizeWithAttributes.h"
#import "MockBadPhotoViewController.h"

@interface WhatPhotosViewController ()

@end

@implementation WhatPhotosViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = GETTING_STARTED_BG_COLOR;

	// Scale the animation up for iPad
	CGAffineTransform xf = CGAffineTransformMakeScale(GETTING_STARTED_WHATPHOTOS_ANIMATION_SCALE, GETTING_STARTED_WHATPHOTOS_ANIMATION_SCALE);
	self.mockBadPhotoContainerView.transform = xf;

    self.educateLabel.text = [MWMessage forKey:@"getting-started-what-photos-educate-label"].text;
    self.avoidLabel.text = [MWMessage forKey:@"getting-started-what-photos-avoid-label"].text;

    self.verticalSpaceBetweenLabels.constant = self.view.frame.size.height * GETTING_STARTED_VERTICAL_SPACE_BETWEEN_LABELS;
    self.verticalSpaceBetweenHalves.constant = self.view.frame.size.height * GETTING_STARTED_VERTICAL_SPACE_BETWEEN_HALVES;

    // Widen the labels for iPad
    self.educateLabelWidth.constant *= GETTING_STARTED_LABEL_WIDTH_MULTIPLIER;
    self.avoidLabelWidth.constant *= GETTING_STARTED_LABEL_WIDTH_MULTIPLIER;

	// Style attributes for labels
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	paragraphStyle.alignment = NSTextAlignmentCenter;
	paragraphStyle.lineSpacing = GETTING_STARTED_LABEL_LINE_SPACING;
	paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
	
	// Apply styled attributes to label resizing it to fit the newly styled text (regardless of i18n string length!)
	[self.educateLabel resizeWithAttributes: @{
					   NSFontAttributeName : [UIFont boldSystemFontOfSize:GETTING_STARTED_HEADING_FONT_SIZE],
			 NSParagraphStyleAttributeName : paragraphStyle,
			NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0f alpha:1.0f]
	 } preferredMaxLayoutWidth:self.educateLabelWidth.constant];
	
	[self.avoidLabel resizeWithAttributes: @{
					 NSFontAttributeName : [UIFont systemFontOfSize:GETTING_STARTED_SUB_HEADING_FONT_SIZE],
		   NSParagraphStyleAttributeName : paragraphStyle,
		  NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0f alpha:0.9f]
	 } preferredMaxLayoutWidth:self.avoidLabelWidth.constant];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{	// Adjust properties on embedded view's view controller
	// Why a segue? See: http://stackoverflow.com/a/13279703
	
	if ([segue.identifier isEqualToString: @"WhatPhotos_MockBadPhoto_Embed"]) {
		MockBadPhotoViewController *mockBadPhotoVC = (MockBadPhotoViewController *) [segue destinationViewController];
		mockBadPhotoVC.animationDelay = GETTING_STARTED_WHATPHOTOS_MOCKBADPHOTO_ANIMATION_DELAY;
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
