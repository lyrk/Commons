//
//  WhatIsCommonsViewController.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/23/13.

#import "WhatIsCommonsViewController.h"
#import "GettingStartedConstants.h"
#import "MWI18N.h"
#import "UILabel+ResizeWithAttributes.h"
#import "UIView+VerticalSpace.h"

@interface WhatIsCommonsViewController ()

@end

@implementation WhatIsCommonsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = GETTING_STARTED_BG_COLOR;
    
    self.contributeLabel.text = [MWMessage forKey:@"getting-started-what-is-commons-contribute-label"].text;
    self.imagesLabel.text = [MWMessage forKey:@"getting-started-what-is-commons-images-label"].text;

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
	 }];
	
	[self.imagesLabel resizeWithAttributes: @{
					  NSFontAttributeName : [UIFont systemFontOfSize:GETTING_STARTED_SUB_HEADING_FONT_SIZE],
			NSParagraphStyleAttributeName : paragraphStyle,
		   NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0f alpha:0.9f]
	 }];
	
	// Ensure constant spacing around the newly resized labels
	[self.contributeLabel moveBelowView:self.containerView spacing:40.0f];
	[self.imagesLabel moveBelowView:self.contributeLabel spacing:22.0f];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
