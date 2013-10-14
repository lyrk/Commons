//
//  SettingsViewController.h
//  Commons-iOS
//
//  Created by Brion on 1/25/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UILabelDynamicHeight;
@class PictureOfTheDayImageView;
@class PictureOfDayCycler;

@interface LoginViewController : UIViewController <UITextFieldDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UIView *usernamePasswordDivider;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UILabelDynamicHeight *loginButton;
@property (weak, nonatomic) IBOutlet UILabelDynamicHeight *logoutButton;
@property (weak, nonatomic) IBOutlet UILabelDynamicHeight *currentUserButton;
@property (weak, nonatomic) IBOutlet UIButton *recoverPasswordButton;

@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UIView *loginInfoContainer;
@property (weak, nonatomic) IBOutlet PictureOfTheDayImageView *potdImageView;

@property (strong, nonatomic) PictureOfDayCycler *pictureOfDayCycler;

-(IBAction)pushedLoginButton:(id)sender;
-(IBAction)pushedLogoutButton:(id)sender;
-(IBAction)pushedCurrentUserButton:(id)sender;
-(IBAction)pushedRecoverPasswordButton:(id)sender;

-(void)showLogout:(BOOL)show;
+(void)applyShadowToView:(UIView *)view;
-(IBAction)pushedAttributionButton:(id)sender;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomSpacerViewToScreenBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *usernamePasswordDividerHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *topSpacer;
@property (weak, nonatomic) IBOutlet UIView *middleSpacer;
@property (weak, nonatomic) IBOutlet UIView *bottomSpacer;

@end
