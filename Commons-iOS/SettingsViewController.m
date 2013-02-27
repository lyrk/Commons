//
//  SettingsViewController.m
//  Commons-iOS
//
//  Created by Brion on 1/25/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "SettingsViewController.h"
#import "CommonsApp.h"
#import "mwapi/MWApi.h"
#import "MWI18N/MWMessage.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // l10n
    self.navigationItem.title = [MWMessage forKey:@"settings-title"].text;
    self.usernameLabel.text = [MWMessage forKey:@"settings-username-label"].text;
    self.usernameField.placeholder = [MWMessage forKey:@"settings-username-placeholder"].text;
    self.passwordLabel.text = [MWMessage forKey:@"settings-password-label"].text;
    self.passwordField.placeholder = [MWMessage forKey:@"settings"].text;
    self.debugModeLabel.text = [MWMessage forKey:@"settings-debug-label"].text;

	// Do any additional setup after loading the view.
    CommonsApp *app = CommonsApp.singleton;
    self.usernameField.text = app.username;
    self.passwordField.text = app.password;

    self.debugModeSwitch.on = app.debugMode;
    [self setDebugModeLabel];

    // Keyboard show/hide listeners to adjust scroll view
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;

    CGRect aRect = self.view.frame;
    aRect.size.height -= keyboardSize.height;
    if (!CGRectContainsPoint(aRect, self.debugModeLabel.frame.origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, self.debugModeLabel.frame.origin.y - (keyboardSize.height-15));
        [self.scrollView setContentOffset:scrollPoint animated:YES];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setUsernameField:nil];
    [self setPasswordField:nil];
    [self setDebugModeSwitch:nil];
    [self setUploadTargetLabel:nil];
    [self setUsernameLabel:nil];
    [self setPasswordLabel:nil];
    [self setDebugModeLabel:nil];
    [super viewDidUnload];
}

- (IBAction)pushedDoneButton:(id)sender {
    
    CommonsApp *app = CommonsApp.singleton;
    
    NSString *username = self.usernameField.text;
    NSString *password = self.passwordField.text;
    
    // Only update & validate user credentials if they have been changed
    if (![app.username isEqualToString:username] || ![app.password isEqualToString:password]) {
        
        // Test credentials to make sure they are valid
        MWApi *mwapi = [app startApi];
        
        MWPromise *login = [mwapi loginWithUsername:username
                                        andPassword:password];
        [login done:^(NSDictionary *loginResult) {
            
            if (mwapi.isLoggedIn) {
                // Credentials verified
                [app log:@"MobileAppLoginAttempts" event:@{
                    @"username": username,
                    @"result": @"success"
                }];
                
                // Save credentials
                app.username = username;
                app.password = password;
                [app saveCredentials];
                [app refreshHistory];
                
                // Dismiss view
                
                [self dismissViewControllerAnimated:YES completion:nil];
                
            } else {
                // Credentials invalid
                [app log:@"MobileAppLoginAttempts" event:@{
                    @"username": username,
                    @"result": loginResult[@"login"][@"result"]
                }];
                
                // Erase saved credentials so that the credentials are validated every time they are changed
                app.username = @"";
                app.password = @"";
                [app saveCredentials];
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[MWMessage forKey:@"error-bad-password-title"].text
                                                                    message:[MWMessage forKey:@"error-bad-password"].text
                                                                   delegate:nil
                                                          cancelButtonTitle:[MWMessage forKey:@"error-dismiss"].text
                                                          otherButtonTitles:nil];
                [alertView show];
            }
        }];
        [login fail:^(NSError *error) {
            
            [app log:@"MobileAppLoginAttempts" event:@{
                @"username": username,
                @"result": @"network"
            }];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[MWMessage forKey:@"error-login-fail"].text
                                                                message:[error localizedDescription]
                                                               delegate:nil
                                                      cancelButtonTitle:[MWMessage forKey:@"error-dismiss"].text
                                                      otherButtonTitles:nil];
            [alertView show];
        }];
        
    }
    else {
    // Credentials have not been changed
        
        NSLog(@"Credentials have not been changed.");
        
        // Dismiss view
               
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)debugSwitchPushed:(id)sender {
    CommonsApp *app = CommonsApp.singleton;
    app.debugMode = self.debugModeSwitch.on;
    [self setDebugModeLabel];
    [app refreshHistory];
}

- (void)setDebugModeLabel
{
    NSString *target;
    if (CommonsApp.singleton.debugMode) {
        target = @"test.wikipedia.org";
    } else {
        target = @"commons.wikimedia.org";
    }
    self.uploadTargetLabel.text = [MWMessage forKey:@"settings-debug-detail" params:@[target]].text;
}

#pragma mark - Text Field Delegate Methods

/**
 * Advance text field to text field with next tag.
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
    NSInteger nextTag = textField.tag + 1;

    UIResponder *nextResponder = [textField.superview viewWithTag:nextTag];
    if (nextResponder) {
        [nextResponder becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    return NO;
}

@end
