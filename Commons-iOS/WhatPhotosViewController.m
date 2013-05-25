//
//  WhatPhotosViewController.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/23/13.

#import "WhatPhotosViewController.h"
#import "GettingStartedConstants.h"
#import "MWI18N.h"

@interface WhatPhotosViewController ()

@end

@implementation WhatPhotosViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = GETTING_STARTED_BG_COLOR;

    self.mockBadPhotoContainerView.transform = CGAffineTransformMakeScale(0.88, 0.88);

    self.educateLabel.text = [MWMessage forKey:@"getting-started-what-photos-educate-label"].text;
    self.avoidLabel.text = [MWMessage forKey:@"getting-started-what-photos-avoid-label"].text;	
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
