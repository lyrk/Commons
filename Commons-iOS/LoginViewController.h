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
@interface LoginViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet GradientButton *loginButton;
@property (weak, nonatomic) IBOutlet GradientButton *logoutButton;
@property (weak, nonatomic) IBOutlet GradientButton *currentUserButton;
@property (weak, nonatomic) IBOutlet UIButton *recoverPasswordButton;

@property (weak, nonatomic) IBOutlet GrayscaleImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UIView *loginInfoContainer;

-(IBAction)pushedLoginButton:(id)sender;
-(IBAction)pushedLogoutButton:(id)sender;
-(IBAction)pushedCurrentUserButton:(id)sender;
-(IBAction)pushedRecoverPasswordButton:(id)sender;

-(void)showLogout:(BOOL)show;

@end
