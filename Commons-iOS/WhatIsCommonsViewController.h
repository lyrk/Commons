//
//  WhatIsCommonsViewController.h
//  Commons-iOS
//
//  Created by Monte Hurd on 5/23/13.

#import <UIKit/UIKit.h>

@interface WhatIsCommonsViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *contributeLabel;
@property (strong, nonatomic) IBOutlet UILabel *imagesLabel;
@property (strong, nonatomic) IBOutlet UIView *mockPageContainerView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *verticalSpaceBetweenLabels;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *verticalSpaceBetweenHalves;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *contributeLabelWidth;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imagesLabelWidth;

@end
