//
//  SettingsViewController.m
//  Commons-iOS
//
//  Created by Brion on 1/25/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "LoginViewController.h"
#import "CommonsApp.h"
#import "mwapi/MWApi.h"
#import "MWI18N/MWMessage.h"
#import "MyUploadsViewController.h"
#import "GradientButton.h"

#define LOGO_SCALE_NON_IPAD_LANDSCAPE 0.43

@interface LoginViewController ()

- (void)hideKeyboard;

@end

@implementation LoginViewController
{

    UITapGestureRecognizer *tapRecognizer;

}

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

	// Get gradent login button color
	[_loginButton useGreenConfirmStyle];
	
    // l10n
    self.navigationItem.title = [MWMessage forKey:@"settings-title"].text;
    self.usernameField.placeholder = [MWMessage forKey:@"settings-username-placeholder"].text;
    self.passwordField.placeholder = [MWMessage forKey:@"settings-password-placeholder"].text;

	// Do any additional setup after loading the view.
    CommonsApp *app = CommonsApp.singleton;
    self.usernameField.text = app.username;
    self.passwordField.text = app.password;

    // Keyboard show/hide listeners to adjust scroll view
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    //hide keyboard when anywhere else is tapped
	tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
	[self.view addGestureRecognizer:tapRecognizer];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
	// When the keyboard is revealed swap the logo and login containers so the keyboard doesn't occlude
	// the login text boxes and login button
	// Shrink and Fade the logo out when doing so for a nice transistion and to focus attention on the
	// login process while the keyboard is visible
	[UIView animateWithDuration:0.2
						  delay:0.0
						options:UIViewAnimationOptionTransitionNone
					 animations:^{
						 // Swap logo and login container positions
						 CGPoint logoCenter = _logoImageView.center;
						 _logoImageView.center = _loginInfoContainer.center;
						 _loginInfoContainer.center = logoCenter;
						 
						 // Shrink and Fade out the logo
						 _logoImageView.transform = CGAffineTransformMakeScale(0.1, 0.1);
						 _logoImageView.alpha = 0.0;
					 }
					 completion:^(BOOL finished){
						 
					 }];
}

- (void)hideKeyboard
{
	// When hiding the keyboard, the logo and login container need to swap positions back to the way
	// they were on the storyboard before the keyboard was shown
	[UIView animateWithDuration:0.2
						  delay:0.0
						options:UIViewAnimationOptionTransitionNone
					 animations:^{
						 // If the positions were not swapped don't swap them back!
						 if (_logoImageView.center.y < _loginInfoContainer.center.y) return;
						 
						 // Perform the position swap
						 CGPoint logoCenter = _logoImageView.center;
						 _logoImageView.center = _loginInfoContainer.center;
						 _loginInfoContainer.center = logoCenter;
						 
						 // Restore the logo alpha and scale to pre-swap settings
						 _logoImageView.alpha = 1.0;
						 
						 if (
							 (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
							 &&
							 UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)
							 ){
							 _logoImageView.transform = CGAffineTransformMakeScale(LOGO_SCALE_NON_IPAD_LANDSCAPE, LOGO_SCALE_NON_IPAD_LANDSCAPE);
						 }else{
							 _logoImageView.transform = CGAffineTransformIdentity;
						 }
					 }
					 completion:^(BOOL finished){
						 
					 }];
	
	// Dismisses the keyboard
	[self.usernameField resignFirstResponder];
	[self.passwordField resignFirstResponder];
	
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
    [super viewDidUnload];
}

-(void)viewWillLayoutSubviews{

	// Position the logo and the login containers centered horizontally and at about one-third and two-thirds
	// the way down the screen vertically respectively
	_logoImageView.center = CGPointMake(self.view.center.x, self.view.frame.size.height / 3.3);
	_loginInfoContainer.center = CGPointMake(self.view.center.x, (self.view.frame.size.height / 2.8) * 2.0);

	// Shrink the logo a bit when the device is held in landscape if the device is not an ipad, also push the
	// logo up a bit in this case (the container center and the logo center get swapped when the keyboard is
	// revealed and pushing the logo up a bit makes the login container more fully fill the space above the
	// top of the keyboard - especially important on non-iPads)
	if (
		(UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
		&&
		UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)
	){
		_logoImageView.transform = CGAffineTransformMakeScale(LOGO_SCALE_NON_IPAD_LANDSCAPE, LOGO_SCALE_NON_IPAD_LANDSCAPE);
		_logoImageView.center = CGPointMake(_logoImageView.center.x, _logoImageView.center.y - 15);
	}else{
		_logoImageView.transform = CGAffineTransformIdentity;
		_logoImageView.center = CGPointMake(_logoImageView.center.x, _logoImageView.center.y + 15);
	}
}

-(void)viewWillAppear:(BOOL)animated{
    
	[self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
	
}

-(void)viewWillDisappear:(BOOL)animated{
	
	UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
								   initWithTitle: @"Accounts"
								   style: UIBarButtonItemStyleBordered
								   target:nil action: nil];
	
	[backButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
										[UIColor colorWithRed:1 green:1 blue:1 alpha:1], UITextAttributeTextColor,
										[NSValue valueWithUIOffset:UIOffsetMake(0.0f, 0.0f)], UITextAttributeTextShadowOffset,
										nil] forState:UIControlStateNormal];
	
	[self.navigationItem setBackBarButtonItem: backButton];
	[self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

- (IBAction)pushedDoneButton:(id)sender {
   
	// Block for pushing the MyUploads view controller on to the navigation controller (used when login
	// credentials have been authenticated)
	void(^showMyUploadsVC)(void) = ^{
		MyUploadsViewController *myUploadsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"MyUploadsViewController"];
		[self.navigationController pushViewController:myUploadsVC animated:YES];
	};

    CommonsApp *app = CommonsApp.singleton;
    
    NSString *username = self.usernameField.text;
    NSString *password = self.passwordField.text;

	// Trim leading and trailing white space from user name and password. This is so the isEqualToString:@"" check below
	// will cause the login to be validated (previously if login info was blank it fell past the credential validation
	// check and crashed)
	username = [username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	password = [password stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    
    // Only update & validate user credentials if they have been changed
    if (
        ![app.username isEqualToString:username]
		||
		![app.password isEqualToString:password]

		// The two cases below force the validation check to happen even on blank user name and/or password entries so
		// an invalid login alert is still shown if no login credentials were entered
		||
		[app.username isEqualToString:@""]
		||
		[app.password isEqualToString:@""]

        ) {
        
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
                
				//login success!
				showMyUploadsVC();
                
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
               
		//login success!
		showMyUploadsVC();
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
