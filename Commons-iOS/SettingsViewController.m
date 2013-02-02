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

	// Do any additional setup after loading the view.
    CommonsApp *app = CommonsApp.singleton;
    self.usernameField.text = app.username;
    self.passwordField.text = app.password;

    self.debugModeSwitch.on = app.debugMode;
    [self setDebugModeLabel];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setUsernameField:nil];
    [self setPasswordField:nil];
    [self setDebugModeSwitch:nil];
    [self setUploadTargetLabel:nil];
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
        
        [mwapi loginWithUsername:username andPassword:password withCookiePersistence:YES onCompletion:^(MWApiResult *loginResult) {
            
            NSLog(@"login: %@", loginResult.data[@"login"][@"result"]);
            
            if (mwapi.isLoggedIn) {
                // Credentials verified
                
                // Save credentials
                app.username = username;
                app.password = password;
                [app saveCredentials];
                
                // Dismiss view
                
                [self dismissViewControllerAnimated:YES completion:nil];
                
            } else {
                // Credentials invalid
                
                NSLog(@"Credentials invalid!");
                
                // Erase saved credentials so that the credentials are validated every time they are changed
                app.username = @"";
                app.password = @"";
                [app saveCredentials];
            }
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
    CommonsApp.singleton.debugMode = self.debugModeSwitch.on;
    [self setDebugModeLabel];
}

- (void)setDebugModeLabel
{
    if (CommonsApp.singleton.debugMode) {
        self.uploadTargetLabel.text = @"Uploading to test.wikipedia.org";
    } else {
        self.uploadTargetLabel.text = @"Uploading to commons.wikimedia.org";
    }
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
