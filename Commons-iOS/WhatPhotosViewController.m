//
//  WhatPhotosViewController.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/23/13.

#import "WhatPhotosViewController.h"
#import "GettingStartedConstants.h"

@interface WhatPhotosViewController ()

@end

@implementation WhatPhotosViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = GETTING_STARTED_BG_COLOR;

    self.mockBadPhotoContainerView.transform = CGAffineTransformMakeScale(0.88, 0.88);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
