//
//  WhatPhotosViewController.h
//  Commons-iOS
//
//  Created by Monte Hurd on 5/23/13.

#import <UIKit/UIKit.h>

@interface WhatPhotosViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *mockBadPhotoContainerView;

@property (strong, nonatomic) IBOutlet UILabel *educateLabel;
@property (strong, nonatomic) IBOutlet UILabel *avoidLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *verticalSpaceBetweenLabels;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *verticalSpaceBetweenHalves;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *educateLabelWidth;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *avoidLabelWidth;

@end
