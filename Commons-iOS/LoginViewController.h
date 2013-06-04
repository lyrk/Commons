//
//  SettingsViewController.h
//  Commons-iOS
//
//  Created by Brion on 1/25/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GradientButton;
@class GrayscaleImageView;
@class PictureOfTheDayImageView;
@interface LoginViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet GradientButton *loginButton;

@property (weak, nonatomic) IBOutlet GrayscaleImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UIView *loginInfoContainer;
@property (weak, nonatomic) IBOutlet PictureOfTheDayImageView *potdImageView;
@property (weak, nonatomic) IBOutlet UIButton *aboutButton;
@property (weak, nonatomic) IBOutlet UIButton *attributionButton;
@property (weak, nonatomic) IBOutlet UILabel *attributionLabel;

- (IBAction)pushedLoginButton:(id)sender;
+ (void)applyShadowToView:(UIView *)view;
- (IBAction)pushedAttributionButton:(id)sender;

@end
