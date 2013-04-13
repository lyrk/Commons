//
//  AboutViewController.h
//  Commons-iOS
//
//  Created by Monte Hurd on 4/12/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GradientButton;

@interface AboutViewController : UIViewController

- (IBAction)openBugs:(id)sender;
- (IBAction)openSource:(id)sender;
- (IBAction)openLicense:(id)sender;
- (IBAction)openCommons:(id)sender;
- (IBAction)openContributors:(id)sender;

@property (weak, nonatomic) IBOutlet GradientButton *bugsButton;
@property (weak, nonatomic) IBOutlet GradientButton *sourceButton;
@property (weak, nonatomic) IBOutlet GradientButton *licenseButton;
@property (weak, nonatomic) IBOutlet GradientButton *commonsButton;
@property (weak, nonatomic) IBOutlet GradientButton *contributorsButton;

@property (weak, nonatomic) IBOutlet UILabel *appNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *appVersionLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end
