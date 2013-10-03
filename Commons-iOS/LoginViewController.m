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
#import "AppDelegate.h"
#import "LoadingIndicator.h"
#import "GettingStartedViewController.h"
#import "QuartzCore/QuartzCore.h"
#import "AspectFillThumbFetcher.h"
#import "PictureOfTheDayImageView.h"
#import "UILabel+ResizeWithAttributes.h"
#import "PictureOfDayCycler.h"
#import "UIView+Debugging.h"

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

#define RESET_PASSWORD_URL @"http://commons.wikimedia.org/wiki/Special:PasswordReset"

// Note: to change the bundled picture of the day simply remove the existing one from the
// bundle, add the new one, then change is date to match the date from the newly bundled
// file name (Nice thing about this approach is the code doesn't have to know anything
// about a special-case file - it works normally with no extra checks)
#define DEFAULT_BUNDLED_PIC_OF_DAY_DATE @"2013-05-24"

// Change this to a plist later, but we're not bundling that many images
#define BUNDLED_PIC_OF_DAY_DATES @"2007-06-15|2008-01-25|2008-11-14|2009-06-19|2010-05-24|2012-07-08|2013-04-21|2013-04-29|2013-05-24|2013-06-04"

// Pic of day transition settings
#define SECONDS_TO_SHOW_EACH_PIC_OF_DAY 6.0f
#define SECONDS_TO_TRANSITION_EACH_PIC_OF_DAY 2.3f

#define PIC_OF_THE_DAY_TO_DOWNLOAD_DAYS_AGO 0 //0 for today, 1 for yesterday, -1 for tomorrow etc

// Force the app to download and cache a particularly interesting picture of the day
// Note: use iPad to retrieve potd image cache files to be bundled
#define FORCE_PIC_OF_DAY_DOWNLOAD_FOR_DATE nil //@"2013-05-24"

@interface LoginViewController ()

@property (weak, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSString *trimmedUsername;
@property (strong, nonatomic) NSString *trimmedPassword;
@property (strong, nonatomic) NSString *pictureOfTheDayUser;
@property (strong, nonatomic) NSString *pictureOfTheDayDateString;
@property (strong, nonatomic) NSString *pictureOfTheDayLicense;
@property (strong, nonatomic) NSString *pictureOfTheDayLicenseUrl;
@property (strong, nonatomic) NSString *pictureOfTheDayWikiUrl;
@property (strong, nonatomic) UILabel *attributionLabel;
@property (strong, nonatomic) UIView *attributionLabelBackground;
@property (strong, nonatomic) NSArray *attributionLabelOffscreenConstraints;
@property (strong, nonatomic) NSArray *attributionLabelOnscreenConstraints;
@property (strong, nonatomic) NSArray *logoImageViewKeyboardOnscreenConstraints;

- (void)showMyUploadsVC;

@end

@implementation LoginViewController
{
    UILongPressGestureRecognizer *longPressRecognizer_;
    UISwipeGestureRecognizer *swipeRecognizerUp_;
    UISwipeGestureRecognizer *swipeRecognizerDown_;
    UISwipeGestureRecognizer *swipeRecognizerLeft_;
    UITapGestureRecognizer *tapRecognizer_;
    UITapGestureRecognizer *doubleTapRecognizer_;
    UITapGestureRecognizer *attributionLabelTapRecognizer_;
    AspectFillThumbFetcher *pictureOfTheDayGetter_;
    BOOL showingPictureOfTheDayAttribution_;
    NSMutableArray *cachedPotdDateStrings_;
    
    // Only skip the login screen on initial load
    BOOL allowSkippingToMyUploads_;
    BOOL isRotating_;
    BOOL isKeyboardOnscreen_;
}

#pragma mark - Init

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super initWithCoder:decoder])
    {
        self.wantsFullScreenLayout = YES;

        allowSkippingToMyUploads_ = YES;
        pictureOfTheDayGetter_ = [[AspectFillThumbFetcher alloc] init];
        self.pictureOfTheDayUser = nil;
        self.pictureOfTheDayDateString = nil;
        self.pictureOfTheDayLicense = nil;
        self.pictureOfTheDayLicenseUrl = nil;
        self.pictureOfTheDayWikiUrl = nil;
        showingPictureOfTheDayAttribution_ = NO;
        cachedPotdDateStrings_ = [[NSMutableArray alloc] init];
        self.potdImageView.image = nil;
        isRotating_ = NO;
        isKeyboardOnscreen_ = NO;

        self.pictureOfDayCycler = [[PictureOfDayCycler alloc] init];
        self.pictureOfDayCycler.dateStrings = cachedPotdDateStrings_;
        self.pictureOfDayCycler.transitionDuration = SECONDS_TO_TRANSITION_EACH_PIC_OF_DAY;
        self.pictureOfDayCycler.displayInterval = SECONDS_TO_SHOW_EACH_PIC_OF_DAY;

        // Create attributionLabel
        self.attributionLabel = [[UILabel alloc] init];
        self.attributionLabel.backgroundColor = [UIColor clearColor];
        self.attributionLabel.hidden = YES;
        self.attributionLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        // Create background view to appear behind attributionLabel
        // (easy way to add padding around the attribution text)
        self.attributionLabelBackground = [[UIView alloc] init];
        self.attributionLabelBackground.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.15f];;
        self.attributionLabelBackground.hidden = YES;
        self.attributionLabelBackground.layer.cornerRadius = 10.0f;
        self.attributionLabelBackground.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return self;
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Get the app delegate so the loading indicator may be accessed
	self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

	// Set gradient buttons color
	[self.loginButton useWhiteStyle];
    [self.logoutButton useWhiteStyle];

    // l10n
    self.usernameField.placeholder = [MWMessage forKey:@"settings-username-placeholder"].text;
    self.passwordField.placeholder = [MWMessage forKey:@"settings-password-placeholder"].text;
    [self.loginButton setTitle:[MWMessage forKey:@"login-button"].text forState:UIControlStateNormal];

    [self.logoutButton setTitle:[MWMessage forKey:@"logout-button"].text forState:UIControlStateNormal];

    [self.recoverPasswordButton setTitle:[MWMessage forKey:@"login-recover-password-button"].text forState:UIControlStateNormal];

    // Disable auto-correct on login boxes
    self.usernameField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
    
    // Gray out the login button if no credentials
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fadeLoginButtonIfNoCredentials) name:UITextFieldTextDidChangeNotification object:self.usernameField];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fadeLoginButtonIfNoCredentials) name:UITextFieldTextDidChangeNotification object:self.passwordField];
    
    [self.loginButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    
	// Do any additional setup after loading the view.
    CommonsApp *app = CommonsApp.singleton;
    self.usernameField.text = app.username;
    self.passwordField.text = app.password;
    
    //hide keyboard when anywhere else is tapped
	tapRecognizer_ = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    tapRecognizer_.numberOfTapsRequired = 1;
	[self.view addGestureRecognizer:tapRecognizer_];

	longPressRecognizer_ = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress)];
    longPressRecognizer_.minimumPressDuration = 1.0f;
	[self.view addGestureRecognizer:longPressRecognizer_];
    
    swipeRecognizerUp_ = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeUp)];
    swipeRecognizerUp_.numberOfTouchesRequired = 1;
    swipeRecognizerUp_.direction = UISwipeGestureRecognizerDirectionUp;
	[self.view addGestureRecognizer:swipeRecognizerUp_];

    swipeRecognizerDown_ = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeDown)];
    swipeRecognizerDown_.numberOfTouchesRequired = 1;
    swipeRecognizerDown_.direction = UISwipeGestureRecognizerDirectionDown;
	[self.view addGestureRecognizer:swipeRecognizerDown_];

    swipeRecognizerLeft_ = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeft)];
    swipeRecognizerLeft_.numberOfTouchesRequired = 1;
    swipeRecognizerLeft_.direction = UISwipeGestureRecognizerDirectionLeft;
	[self.view addGestureRecognizer:swipeRecognizerLeft_];

    doubleTapRecognizer_ = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap)];
    doubleTapRecognizer_.numberOfTapsRequired = 2;
	[self.view addGestureRecognizer:doubleTapRecognizer_];
    doubleTapRecognizer_.enabled = NO;
   
    attributionLabelTapRecognizer_ = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleAttributionLabelTap:)];
    attributionLabelTapRecognizer_.numberOfTapsRequired = 1;
    [self.attributionLabel addGestureRecognizer:attributionLabelTapRecognizer_];
    self.attributionLabel.userInteractionEnabled = YES;

    [self fadeLoginButtonIfNoCredentials];

    self.potdImageView.useFilter = NO;

    // Ensure bundled pic of day is in cache
    [self copyToCacheBundledPotdsNamed:BUNDLED_PIC_OF_DAY_DATES extension:@"dict"];
    [self copyToCacheBundledPotdsNamed:BUNDLED_PIC_OF_DAY_DATES extension:@"jpg"];

    if(FORCE_PIC_OF_DAY_DOWNLOAD_FOR_DATE == nil){
        // Load default image to ensure something is showing even if no net connection
        // (loads the copy of the bundled default potd which was copied to the cache)
        [self getPictureOfTheDayForDateString:DEFAULT_BUNDLED_PIC_OF_DAY_DATE done:nil];
    }

    _logoImageView.alpha = 1.0f;
    _usernameField.alpha = 1.0f;
    _passwordField.alpha = 1.0f;
    _loginButton.alpha = 1.0f;
    
    // Add shadow behind the login text boxes and buttons so they stand out on light background
    [LoginViewController applyShadowToView:self.loginInfoContainer];
    [LoginViewController applyShadowToView:self.aboutButton];    
    [LoginViewController applyShadowToView:self.attributionButton];
    [LoginViewController applyShadowToView:self.recoverPasswordButton];
    [LoginViewController applyShadowToView:self.logoImageView];

    // The "cycle" callback below is invoked by self.pictureOfDayCycler to change which picture of the day is showing
    __weak LoginViewController *weakSelf = self;
    __weak NSMutableArray *weakCachedPotdDateStrings_ = cachedPotdDateStrings_;
    // todayDateString must be set *inside* cycle callback! it's used to see if midnight rolled around while the images
    // were transitioning. if so it adds a date string for the new day to cachedPotdDateStrings_ so the new day's image
    // will load (previously you had to leave the login page and go back to see the new day's image)
    __block NSString *todayDateString = nil;
    __weak PictureOfDayCycler *weakPictureOfDayCycler_ = self.pictureOfDayCycler;
    self.pictureOfDayCycler.cycle = ^(NSString *dateString){
        // If today's date string is not in cachedPotdDateStrings_ (can happen if the login page is displaying and
        // midnight occurs) add it so it will be downloaded.
        todayDateString = [weakSelf getDateStringForDaysAgo:0];
        if(![weakCachedPotdDateStrings_ containsObject:todayDateString]){
            [weakCachedPotdDateStrings_ addObject:todayDateString];
            // Stop the cycler while the new day's image is retrieved - otherwise the cycler moves on, then whenever
            // the image is retrieved the callback is invoked causing it to display even if this happens in the middle
            // of another image's cycle - this looks jarring, so stop cycling until new image is grabbed
            [weakPictureOfDayCycler_ stop];
            dateString = todayDateString;
            //[weakPictureOfDayCycler_ moveIndexToEnd];
        }
        //NSLog(@"\n\nweakCachedPotdDateStrings_ = \n\n%@\n\n", weakCachedPotdDateStrings_);
        [weakSelf getPictureOfTheDayForDateString:dateString done:^{
            if ([dateString isEqualToString:todayDateString]) {
                // If the cycler was stopped because midnight rolled around, restart it
                [weakPictureOfDayCycler_ start];
            }
        }];
    };

    // Round username and pwd box corners
    [app roundCorners:UIRectCornerTopLeft|UIRectCornerTopRight ofView:self.usernameField toRadius:10.0];
	[app roundCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight ofView:self.passwordField toRadius:10.0];

    // Center align username and pwd box text
    self.usernameField.textAlignment = NSTextAlignmentCenter;
    self.passwordField.textAlignment = NSTextAlignmentCenter;
    
    // Observe changes to username and pwd box text so placeholder text can be updated
    [self.usernameField addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [self.passwordField addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];

    // Prepare the attributionLabel
    [self.view addSubview:self.attributionLabelBackground];
    [self.view addSubview:self.attributionLabel];
    
    // Setup constraints to control attributionLabel layout
    [self setupAttributionLabelConstraints];
    
    // Hide the logo when the keyboard is visible
    self.logoImageViewKeyboardOnscreenConstraints = [NSLayoutConstraint
                                                     constraintsWithVisualFormat: @"V:[logoImageView(0)]"
                                                     options:  0
                                                     metrics:  0
                                                     views:    @{@"logoImageView" : self.logoImageView}
                                                     ];
    //[self.view randomlyColorSubviews];
}

-(void)viewWillAppear:(BOOL)animated{

    // Because tapping currentUserButton pushes a view controller onto the navigation controller stack
    // the currentUserButton can shuffle offscreen before it completely finishes updating itself from
    // its selected visual state to its unselected visual state. When this happens, when the view
    // which was pushed gets popped, the currentUserButton can appear to be pushed - visually a bit
    // more dark. setNeedsDisplay tells it to draw itself again
    [self.currentUserButton setNeedsDisplay];
    
	[self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
	
    // The wikimedia picture of the day urls use yyyy-MM-dd format - get such a string
    NSString *dateString = [self getDateStringForDaysAgo:PIC_OF_THE_DAY_TO_DOWNLOAD_DAYS_AGO];
    
    if(FORCE_PIC_OF_DAY_DOWNLOAD_FOR_DATE != nil){
        dateString = FORCE_PIC_OF_DAY_DOWNLOAD_FOR_DATE;
    }

    // Populate array cachedPotdDateStrings_ with all cached potd file date strings
    [self loadArrayOfCachedPotdDateStrings];
    // If dateString not already in cachedPotdDateStrings_ 
    if (![cachedPotdDateStrings_ containsObject:dateString]) {
        // Download the current PotD!
        [self getPictureOfTheDayForDateString:dateString done:^{
            // Update "cachedPotdDateStrings_" so it contains date string for the newly downloaded file
            [self loadArrayOfCachedPotdDateStrings];
            [self.pictureOfDayCycler start];
        }];
    }else{
        [self.pictureOfDayCycler start];
    }
}

-(void)viewDidDisappear:(BOOL)animated{

    // Disables keyboard listeners when this view controller's view is not visible
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];

    // Ensure keyboard is hidden - sometimes it can hang around otherwise
	[self.usernameField resignFirstResponder];
	[self.passwordField resignFirstResponder];
}

-(void)viewWillDisappear:(BOOL)animated{
    [self.pictureOfDayCycler stop];

    [super viewWillDisappear:animated];
}

-(void)viewDidAppear:(BOOL)animated{
    
    // Enable keyboard show listener only while this view controller's view is visible (this observer is removed
    // in viewDidDisappear. When we didn't remove it in viewDidDisappear this view controller was receiving
    // notifications even when its view wasn't even visible!)
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    // Automatically show the getting started pages, but only once and only if no credentials present
    [self performSelector:@selector(showGettingStartedAutomaticallyOnce) withObject:nil afterDelay:2.0f];
    
    [super viewDidAppear:animated];
}

#pragma mark - Utility

+ (void)applyShadowToView:(UIView *)view{

    // "shouldRasterize" improves shadow performance: http://stackoverflow.com/a/7867703/135557
    // This is especially noticable on old 3.5 inch devices during pic of the day transitions
    view.layer.shouldRasterize = YES;
    view.layer.rasterizationScale = [[UIScreen mainScreen] scale];

    // Apply shadow
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOffset = CGSizeMake(0, 0);
    view.layer.shadowOpacity = 1;
    view.layer.shadowRadius = 6.0;
    view.clipsToBounds = NO;
}

#pragma mark - Other view controllers

-(void)showGettingStartedAutomaticallyOnce
{
    // Automatically show the getting started pages, but only once and only if no credentials present
    if(
       ([self trimmedUsername].length == 0)
       &&
       ([self trimmedPassword].length == 0)
       &&
       ![[NSUserDefaults standardUserDefaults] boolForKey:@"GettingStartedWasAutomaticallyShown"]
       )
    {
        GettingStartedViewController *gettingStartedVC = [self.storyboard instantiateViewControllerWithIdentifier:@"GettingStartedViewController"];
        [self presentViewController:gettingStartedVC animated:YES completion:nil];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"GettingStartedWasAutomaticallyShown"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

-(void)showMyUploadsVC{
    // For pushing the MyUploads view controller on to the navigation controller (used when login
    // credentials have been authenticated)
    MyUploadsViewController *myUploadsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"MyUploadsViewController"];
    [self.navigationController pushViewController:myUploadsVC animated:YES];
    
    // Show logout elementes after slight delay. if the login page is sliding offscreen it looks odd
    // to update its interface elements as it's sliding away - the delay fixes this
    float delayInSeconds = 0.25;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        // Executed on the main queue after delay
        [self showLogout:YES];
    });
}

#pragma mark - Buttons

- (void)fadeLoginButtonIfNoCredentials
{
    [self.loginButton setTitleColor:
     (!self.trimmedUsername.length || !self.trimmedPassword.length) ? [UIColor grayColor] : [UIColor blackColor]
                           forState:UIControlStateNormal];
}

- (IBAction)pushedLogoutButton:(id)sender
{
    CommonsApp *app = CommonsApp.singleton;
    [app.fetchDataURLQueue cancelAllOperations];
    [app deleteAllRecords];
    [app clearKeychainCredentials];
    app.debugMode = NO;
    self.usernameField.text = @"";
    self.passwordField.text = @"";

    [self revealLoginFieldsWithAnimation];
}

-(IBAction)pushedCurrentUserButton:(id)sender
{
    [self showMyUploadsVC];
}

-(IBAction)pushedRecoverPasswordButton:(id)sender
{
    CommonsApp *app = CommonsApp.singleton;
    [app openURLWithDefaultBrowser:[NSURL URLWithString:RESET_PASSWORD_URL]];
}

- (IBAction)pushedLoginButton:(id)sender
{
    // If username or password are blank set focus on the first one which is blank and return
    if ([self setTextInputFocusOnEmptyField]) return;
    
    CommonsApp *app = CommonsApp.singleton;
    
    allowSkippingToMyUploads_ = NO;

	// Trim leading and trailing white space from user name and password. This is so the isEqualToString:@"" check below
	// will cause the login to be validated (previously if login info was blank it fell past the credential validation
	// check and crashed)
    NSString *username = self.trimmedUsername;
    NSString *password = self.trimmedPassword;
    
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
        
		// Show the loading indicator wheel
		[self.appDelegate.loadingIndicator show];
		
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
                [app deleteAllRecords];
                
                [self.passwordField resignFirstResponder];
                
                MWPromise *refresh = [app refreshHistoryWithFailureAlert:YES];
                [refresh always:^(id arg) {
                    // Login success! Show MyUploads view
                    [self showMyUploadsVC];
                }];
                
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
                [app deleteAllRecords];
                
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
        
        [login always:^(NSDictionary *loginResult) {
			// Hide the loading indicator wheel
			[self.appDelegate.loadingIndicator hide];
        }];
    }
    else {
        // Credentials have not been changed
        
        NSLog(@"Credentials have not been changed.");
        
        // Dismiss view

		//login success!
        [self showMyUploadsVC];
    }
}

-(void)showLogout:(BOOL)show
{
    self.logoutButton.hidden = !show;
    self.currentUserButton.hidden = !show;
    self.loginButton.hidden = show;
    self.usernameField.hidden = show;
    self.passwordField.hidden = show;
    self.recoverPasswordButton.hidden = show;

    [self.currentUserButton setTitle:[MWMessage forKey:@"login-current-user-button" param:self.usernameField.text].text forState:UIControlStateNormal];
    
    // Size currentUserButton to fix whatever text it now contains
    CGRect f = self.currentUserButton.frame;
    CGSize s = [self.currentUserButton sizeThatFits:self.currentUserButton.frame.size];
    // Add padding to right and left of re-sized currentUserButton's text
    f.size.width = s.width + 40.0f;
    // If resized currentUserButton is narrower than the logout button make it same width as logout button
    f.size.width = (f.size.width < self.logoutButton.frame.size.width) ? self.logoutButton.frame.size.width : f.size.width;
    self.currentUserButton.frame = f;
    // Re-center currentUserButton above logout button
    self.currentUserButton.center = CGPointMake(self.logoutButton.center.x, self.currentUserButton.center.y);
    
}

-(void)revealLoginFieldsWithAnimation
{
    CGPoint origCurrentUserButtonCenter = self.currentUserButton.center;
    self.logoutButton.layer.zPosition = self.currentUserButton.layer.zPosition + 1;
    // Animate currentUserButton to slide down behind logoutButton
    [UIView animateWithDuration:0.15f
                          delay:0.0f
                        options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         self.currentUserButton.center = self.logoutButton.center;
                         self.currentUserButton.alpha = 0.0f;
                     }
                     completion:^(BOOL finished){
                         
                         // Now animate usernameField and passwordField sliding up
                         self.currentUserButton.hidden = YES;
                         self.currentUserButton.center = origCurrentUserButtonCenter;
                         self.loginButton.alpha = 0.0f;
                         self.usernameField.alpha = 0.0f;
                         self.passwordField.alpha = 0.0f;
                         self.recoverPasswordButton.alpha = 0.0f;
                         self.loginButton.hidden = NO;
                         self.usernameField.hidden = NO;
                         self.passwordField.hidden = NO;
                         self.recoverPasswordButton.hidden = NO;

                         CGRect origUsernameFieldFrame = self.usernameField.frame;
                         CGRect origPasswordFieldFrame = self.passwordField.frame;
                         float vOffset = self.loginButton.frame.origin.y - self.usernameField.frame.origin.y;
                         self.usernameField.center = CGPointMake(self.usernameField.center.x, self.usernameField.center.y + vOffset);
                         self.passwordField.center = CGPointMake(self.passwordField.center.x, self.passwordField.center.y + vOffset);
                         [UIView animateWithDuration:0.15f
                                               delay:0.0f
                                             options:UIViewAnimationOptionTransitionNone
                                          animations:^{
                                              
                                              self.usernameField.alpha = 1.0f;
                                              self.passwordField.alpha = 1.0f;
                                              
                                              self.recoverPasswordButton.alpha = 1.0f;
                                              self.loginButton.alpha = 1.0f;
                                              // If either username or password blank fade the login button
                                              [self fadeLoginButtonIfNoCredentials];
                                              
                                              self.logoutButton.alpha = 0.0f;
                                              
                                              self.usernameField.frame = origUsernameFieldFrame;
                                              self.passwordField.frame = origPasswordFieldFrame;
                                          }
                                          completion:^(BOOL finished){
                                              // Reset logout state
                                              [self showLogout:NO];
                                              // Ensure login button isn't stuck drawn selected
                                              [self.loginButton setNeedsDisplay];
                                              // The logout button is hidden by now, but ensure it can be seen the next time it is animated
                                              self.logoutButton.alpha = 1.0f;
                                              self.currentUserButton.alpha = 1.0f;
                                          }];
                     }];
}

#pragma mark - Layout

-(void)viewWillLayoutSubviews{

    [super viewWillLayoutSubviews];
}

#pragma mark - Rotation

-(BOOL)shouldAutorotate
{
    // Required for supportedInterfaceOrientations to be called
    return YES;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    isRotating_ = YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    isRotating_ = NO;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Pic of Day

-(void)copyToCacheBundledPotdsNamed:(NSString *)defaultBundledPotdsDates extension:(NSString *)extension
{
    NSArray *dates = [defaultBundledPotdsDates componentsSeparatedByString:@"|"];
    for (NSString *bundledPotdDateString in dates) {
        // Copy bundled default picture of the day to the cache (if it's not already there)
        // so there's a pic of the day shows even if today's image can't download
        NSString *defaultBundledPotdFileName = [NSString stringWithFormat:@"POTD-%@.%@", bundledPotdDateString, extension];
        NSString *defaultBundledPath = [[NSBundle mainBundle] pathForResource:defaultBundledPotdFileName ofType:nil];
        if (defaultBundledPath){
            //Bundled File Found! See: http://stackoverflow.com/a/7487235
            NSFileManager *fm = [NSFileManager defaultManager];
            NSString *cachePotdPath = [[CommonsApp singleton] potdPath:defaultBundledPotdFileName];
            if (![fm fileExistsAtPath:cachePotdPath]) {
                // Cached version of bundle file not found, so copy bundle file to cache!
                [fm copyItemAtPath:defaultBundledPath toPath:cachePotdPath error:nil];
            }else{
                // Cached version was found, so check if bundled file differs from existing cached file by comparing last modified dates
                NSError *error = nil;
                NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:defaultBundledPath error:&error];
                NSDate *bundledFileModDate = [fileAttributes objectForKey:NSFileModificationDate];
                fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:cachePotdPath error:&error];
                NSDate *cachedFileModDate = [fileAttributes objectForKey:NSFileModificationDate];
                if (![cachedFileModDate isEqualToDate:bundledFileModDate]) {
                    // Remove the cached version
                    [fm removeItemAtPath:cachePotdPath error:&error];
                    // Bundled version newer than cached version, so copy bundle file to cache
                    [fm copyItemAtPath:defaultBundledPath toPath:cachePotdPath error:&error];
                }
            }
        }
    }
}

-(void)loadArrayOfCachedPotdDateStrings
{
    [cachedPotdDateStrings_ removeAllObjects];
    
    // Get array cachedPotdDateStrings_ of cached potd date strings
    // Uses reverseObjectEnumerator so most recently downloaded images show first
    NSArray *allFileInPotdFolder = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[CommonsApp singleton] potdPath:@""] error:nil];
    for (NSString *fileName in [allFileInPotdFolder reverseObjectEnumerator]) {
        if ([fileName hasPrefix:@"POTD-"] && [fileName hasSuffix:@"dict"]) {
            NSString *dateString = [fileName substringWithRange:NSMakeRange(5, 10)];
            [cachedPotdDateStrings_ addObject:dateString];
        }
    }

    // Move the default bundled image to the end of the array so it doesn't show again
    // until the other images have been cycled through
    [cachedPotdDateStrings_ removeObject:DEFAULT_BUNDLED_PIC_OF_DAY_DATE];
    [cachedPotdDateStrings_ addObject:DEFAULT_BUNDLED_PIC_OF_DAY_DATE];

    //NSLog(@"\n\ncachedPotdDateStrings_ = \n\n%@\n\n", cachedPotdDateStrings_);
}

-(NSString *)getDateStringForDaysAgo:(int)daysAgo
{
    NSDate *date = [[NSDate alloc] init];
    date = [date dateByAddingTimeInterval: -(86400.0 * daysAgo)];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    return [formatter stringFromDate:date];
}

-(void)getPictureOfTheDayForDateString:(NSString *)dateString done:(void(^)(void)) done
{
    // Prepare callback block for getting picture of the day
    __weak PictureOfTheDayImageView *weakPotdImageView = self.potdImageView;
    __weak LoginViewController *weakSelf = self;

    // Determine the resolution of the picture of the day to request
    CGSize screenSize = self.view.bounds.size;
    // For now leave scale at one - retina iPads would request too high a resolution otherwise
    CGFloat scale = 1.0f; //[[UIScreen mainScreen] scale];
    
    MWPromise *fetch = [pictureOfTheDayGetter_ fetchPictureOfDay:dateString size:CGSizeMake(screenSize.width * scale, screenSize.height * scale) withQueuePriority:NSOperationQueuePriorityHigh];
    
    [fetch done:^(NSDictionary *dict) {
        if (dict) {
            NSData *imageData = dict[@"image"];
            if (imageData) {
                UIImage *image = [UIImage imageWithData:imageData scale:1.0];

                weakSelf.pictureOfTheDayUser = dict[@"user"];
                weakSelf.pictureOfTheDayDateString = dict[@"potd_date"];
                weakSelf.pictureOfTheDayLicense = dict[@"license"];
                weakSelf.pictureOfTheDayLicenseUrl = dict[@"licenseurl"];
                weakSelf.pictureOfTheDayWikiUrl = dict[@"descriptionurl"];
                
                // Briefly hide the attribution label before updating it
                [UIView animateWithDuration:self.pictureOfDayCycler.transitionDuration / 4.0
                                      delay:0.0
                                    options: UIViewAnimationCurveLinear
                                 animations:^{
                                     weakSelf.attributionLabel.alpha = 0.0f;
                                     weakSelf.attributionLabelBackground.alpha = 0.0f;
                                 }
                                 completion:^(BOOL finished){
                                     // Update the attribution text
                                     [weakSelf updateAttributionLabelText];

                                     //Now show the updated attribution box
                                     [UIView animateWithDuration:self.pictureOfDayCycler.transitionDuration / 3.0
                                                           delay:0.0
                                                         options: UIViewAnimationCurveLinear
                                                      animations:^{
                                                          weakSelf.attributionLabelBackground.alpha = 1.0f;
                                                          weakSelf.attributionLabel.alpha = 1.0f;
                                                      }
                                                      completion:^(BOOL finished){
                                                      }];
                                 }];

                // Cross-fade between pictures of the day
                [CATransaction begin];
                CATransition *crossFade = [CATransition animation];
                crossFade.type = kCATransitionFade;
                crossFade.duration = self.pictureOfDayCycler.transitionDuration;
                crossFade.removedOnCompletion = YES;
                [CATransaction setCompletionBlock:^{
                    if(done) done();
                }];
                [[weakPotdImageView layer] addAnimation:crossFade forKey:@"Fade"];
                [CATransaction commit];

                weakPotdImageView.image = image;
            }
        }
    }];

    // Cycle through cached images even of there was problem downloading a new one
    [fetch fail:^(NSError *error) {
        NSLog(@"PictureOfTheDay Error: %@", error.description);
        if(done) done();
    }];

    [fetch always:^(id obj) {

    }];
}

#pragma mark - Pic of Day attribution

- (IBAction)pushedAttributionButton:(id)sender{
    if (!showingPictureOfTheDayAttribution_) {
        [self showAttributionLabel];
    }else{
        [self hideAttributionLabel];
    }

    NSLog(@"pictureOfTheDayUser = %@", self.pictureOfTheDayUser);
    NSLog(@"pictureOfTheDayDateString = %@", self.pictureOfTheDayDateString);
    NSLog(@"pictureOfTheDayLicense = %@", self.pictureOfTheDayLicense);
    NSLog(@"pictureOfTheDayLicenseUrl = %@", self.pictureOfTheDayLicenseUrl);
}

-(void)updateAttributionLabelText
{
    // Convert the date string to an NSDate
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *date = [dateFormatter dateFromString:self.pictureOfTheDayDateString];
    
    // Now get nice readable date for current locale
    NSString *formatString = [NSDateFormatter dateFormatFromTemplate:@"EdMMMy" options:0 locale:[NSLocale currentLocale]];
    [dateFormatter setDateFormat:formatString];
    
    NSString *prettyDateString = [dateFormatter stringFromDate:date];
    NSString *picOfTheDayText = [MWMessage forKey:@"picture-of-day-label"].text;
    NSString *picOfTheAuthorText = [MWMessage forKey:@"picture-of-day-author"].text;
    NSString *picOfTheDayLicenseName = [self.pictureOfTheDayLicense uppercaseString];

    // If license was name was not retrieved change it to say "Tap for License" for now
    if (picOfTheDayLicenseName == nil){
        picOfTheDayLicenseName = [MWMessage forKey:@"picture-of-day-tap-for-license"].text;
    }

    float fontSize =            (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 30.0f : 15.0f;
    float lineSpacing =         (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 16.0f : 8.0f;

    // Style attributes for labels
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.paragraphSpacing = lineSpacing;
    //paragraphStyle.lineSpacing = lineSpacing;

    NSString *attributeString = [NSString stringWithFormat:@"%@\n%@\n%@ %@\n%@", picOfTheDayText, prettyDateString, picOfTheAuthorText, self.pictureOfTheDayUser, picOfTheDayLicenseName];

    self.attributionLabel.attributedText = [[NSAttributedString alloc] initWithString:attributeString attributes: @{
            NSFontAttributeName : [UIFont boldSystemFontOfSize:fontSize],
            NSParagraphStyleAttributeName : paragraphStyle,
            NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0f alpha:1.0f]
    }];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {

    if(actionSheet.cancelButtonIndex == buttonIndex){
        // On iPad the action sheet can be dismissed by tapping outside the action sheet
        // On non-iPad the cancel button dismisses the action sheet
        self.attributionLabel.alpha = 1.0f;
        self.attributionButton.alpha = 1.0f;
        self.attributionLabelBackground.alpha = 1.0f;
        return;
    }

    // If license name was not retrieved make the license button open the wiki page for now
    // (the wiki page should have license info so at least the user is pointed in the right direction)
    if (self.pictureOfTheDayLicense == nil) buttonIndex = 0;

    NSString *urlToOpen = nil;
    switch (buttonIndex) {
        case 0:
            urlToOpen = self.pictureOfTheDayWikiUrl;
            break;
        case 1:
            urlToOpen = [NSString stringWithFormat:@"%@%@", @"http:", self.pictureOfTheDayLicenseUrl];
            break;
        default:
            break;
    }
    if (urlToOpen) [CommonsApp.singleton openURLWithDefaultBrowser:[NSURL URLWithString:urlToOpen]];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // Ensure the cycler is restarted. Added this because on iPad action sheet
    // there is no "Cancel" button so "actionSheet:clickedButtonAtIndex:" doesn't
    // get called when action sheet is dismissed on iPad
    [self.pictureOfDayCycler start];
}

-(void)handleAttributionLabelTap:(UITapGestureRecognizer *)recognizer
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[MWMessage forKey:@"picture-of-day-menu-title"].text
                                                             delegate:self
                                                    cancelButtonTitle:[MWMessage forKey:@"picture-of-day-cancel-button"].text
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:[MWMessage forKey:@"picture-of-day-commons-button"].text,
                                                    [MWMessage forKey:@"picture-of-day-license-button"].text, nil];
    actionSheet.actionSheetStyle = UIBarStyleBlackTranslucent;
    [actionSheet showInView:self.view];
    [self.pictureOfDayCycler stop];
    self.attributionLabel.alpha = 0.0f;
    self.attributionLabelBackground.alpha = 0.0f;
    self.attributionButton.alpha = 0.0f;
}

-(void)showAttributionLabel
{
    showingPictureOfTheDayAttribution_ = YES;

    [self updateAttributionLabelText];

    self.attributionLabel.hidden = NO;
    self.attributionLabelBackground.hidden = NO;

    // Move the attribution label onscreen
    [self.view removeConstraints:self.attributionLabelOffscreenConstraints];
    [self.view addConstraints:self.attributionLabelOnscreenConstraints];

    [UIView animateWithDuration:0.2f
                          delay:0.0f
                        options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         self.logoImageView.alpha = 0.0f;
                         self.loginInfoContainer.alpha = 0.0f;
                         self.aboutButton.alpha = 0.0f;
                         // Cause the constraint changes to be animated
                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished){
                         self.logoImageView.hidden = YES;
                         self.loginInfoContainer.hidden = YES;
                         self.aboutButton.hidden = YES;
                     }];
    
    // Apply shadow to text (label is transparent now)
    [LoginViewController applyShadowToView:self.attributionLabel];    
}

-(void)hideAttributionLabel
{
    showingPictureOfTheDayAttribution_ = NO;

    self.logoImageView.hidden = NO;
    self.loginInfoContainer.hidden = NO;
    self.aboutButton.hidden = NO;

    [self.view removeConstraints:self.attributionLabelOnscreenConstraints];
    [self.view addConstraints:self.attributionLabelOffscreenConstraints];

    [UIView animateWithDuration:0.2f
                          delay:0.0f
                        options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         self.logoImageView.alpha = 1.0f;
                         self.loginInfoContainer.alpha = 1.0f;
                         self.aboutButton.alpha = 1.0f;
                         // Cause the constraint changes to be animated
                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished){
                         self.attributionLabel.hidden = YES;
                         self.attributionLabelBackground.hidden = YES;
                     }];
}

-(void)makeAttributionLabelHugText
{
    // Make label hug its text: http://stackoverflow.com/a/16009707
    // Expands vertically as necessary
    CGSize attributionLabelSize = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? CGSizeMake(360.0f, 375.0f) : CGSizeMake(175.0f, 175.0f);
    NSDictionary *metrics = @{@"width" : @(attributionLabelSize.width)};
    
    self.attributionLabel.numberOfLines = 0;
    self.attributionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.attributionLabel.preferredMaxLayoutWidth = attributionLabelSize.width;
    
    [self.attributionLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.attributionLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    
    NSArray* constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[_attributionLabel(width)]" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(_attributionLabel)];
    [self.view addConstraints:constraints];
    
    [self.attributionLabel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_attributionLabel(220@300)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_attributionLabel)]];
}

-(void)setupAttributionLabelConstraints
{
    // Make attribution label be just a bit bigger than the text it displays
    [self makeAttributionLabelHugText];
    
    // Center the attribution label
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.attributionLabel
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1
                                                           constant:0]];
    
    // Create constraint for hiding the attributionLabel below self.view
    self.attributionLabelOffscreenConstraints = [NSLayoutConstraint
                                                 constraintsWithVisualFormat: @"V:[view]-margin-[attributionLabel]"
                                                 options:  0
                                                 metrics:  @{@"margin" : @(15)}
                                                 views:    @{@"view" : self.view, @"attributionLabel" : self.attributionLabel}
                                                 ];
    
    // Create constraint for placing attributionLabel just above the bottom of self.view
    self.attributionLabelOnscreenConstraints = [NSLayoutConstraint
                                                constraintsWithVisualFormat: @"V:[attributionLabel]-margin-|"
                                                options:  NSLayoutFormatAlignAllBottom
                                                metrics:  @{@"margin" : @((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 30 : 17)}
                                                views:    @{@"attributionLabel" : self.attributionLabel}
                                                ];
    
    // Initially use the constraint which hides the attributionLabel
    [self.view addConstraints:self.attributionLabelOffscreenConstraints];
    
    // Size attributionLabelBackground to match attributionLabel plus margin
    float margin = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 10 : 5;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.attributionLabelBackground
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.attributionLabel
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1
                                                           constant:-margin]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.attributionLabelBackground
                                                          attribute:NSLayoutAttributeRight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.attributionLabel
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1
                                                           constant:margin]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.attributionLabelBackground
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.attributionLabel
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1
                                                           constant:-margin]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.attributionLabelBackground
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.attributionLabel
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1
                                                           constant:margin]];
}

#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification *)notification
{
    [self showPlaceHolderTextIfNecessary];

    self.recoverPasswordButton.hidden = YES;
    self.recoverPasswordButtonHeightConstraint.constant = 0.0f;

    // Shrink the logo
    [self.view addConstraints:self.logoImageViewKeyboardOnscreenConstraints];
    
    // Move the bottom spacer's bottom up to the top of the keyboard
    NSDictionary *info = [notification userInfo];
    CGRect keyboardWindowRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardViewRect = [self.view convertRect:keyboardWindowRect fromView:nil];
    self.bottomSpacerViewToScreenBottomConstraint.constant = keyboardViewRect.size.height;

    isKeyboardOnscreen_ = YES;

    if (isRotating_) {
        [self.view layoutIfNeeded];
    }else{
        [UIView animateWithDuration:0.2f
                              delay:0.0f
                            options:UIViewAnimationOptionTransitionNone
                         animations:^{
                             // Cause the constraint changes to be animated
                             [self.view layoutIfNeeded];
                         }
                         completion:^(BOOL finished){
                         }];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    [self showPlaceHolderTextIfNecessary];

    // Reset the image logo size
    [self.view removeConstraints:self.logoImageViewKeyboardOnscreenConstraints];
    // Move the bottom spacer's bottom back to the bottom of the screen
    
    self.bottomSpacerViewToScreenBottomConstraint.constant = 0;
    self.recoverPasswordButton.hidden = NO;
    self.recoverPasswordButtonHeightConstraint.constant = 30.0f;
    
    isKeyboardOnscreen_ = NO;
    
    if (isRotating_) {
        [self.view layoutIfNeeded];
    }else{
        [UIView animateWithDuration:0.2f
                              delay:0.0f
                            options:UIViewAnimationOptionTransitionNone
                         animations:^{
                             // Cause the constraint changes to be animated
                             [self.view layoutIfNeeded];
                         }
                         completion:^(BOOL finished){
                         }];
    }

    doubleTapRecognizer_.enabled = NO;
}

-(void)hideKeyboard
{
    [self.usernameField resignFirstResponder];
	[self.passwordField resignFirstResponder];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    doubleTapRecognizer_.enabled = YES;
}

#pragma mark - Text fields

-(BOOL)setTextInputFocusOnEmptyField
{
    // Sets focus on first empty username or password field returning YES if it does so
    // Returns no if no blank fields found
    UITextField *textFieldInNeedOfInput = [self getTextFieldInNeedOfInput];
    if (textFieldInNeedOfInput) {
        [textFieldInNeedOfInput becomeFirstResponder];
        return YES;
    }else{
        return NO;
    }
}

-(UITextField *)getTextFieldInNeedOfInput
{
    // If neither username nor password, return username field
    if(!self.trimmedUsername.length && !self.trimmedPassword.length) return self.usernameField;
    
    // If some username but no password return password field
    if(self.trimmedUsername.length && !self.trimmedPassword.length) return self.passwordField;
    
    // If some password but no username return username field
    if(!self.trimmedUsername.length && self.trimmedPassword.length) return self.usernameField;

    return nil;
}

-(NSString *) trimmedUsername{
    // Returns trimmed version of the username as it *presently exists* in the usernameField UITextField
    return [CommonsApp.singleton getTrimmedString:self.usernameField.text];
}

-(NSString *) trimmedPassword{
    // Returns trimmed version of the password as it *presently exists* in the passwordField UITextField
    return [CommonsApp.singleton getTrimmedString:self.passwordField.text];
}

- (void)showPlaceHolderTextIfNecessary
{
    if (self.usernameField.text.length == 0) {
        self.usernameField.placeholder = [MWMessage forKey:@"settings-username-placeholder"].text;
    }

    if (self.passwordField.text.length == 0) {
        self.passwordField.placeholder = [MWMessage forKey:@"settings-password-placeholder"].text;
    }
}

#pragma mark - Gesture

-(void)handleTap
{
    if (showingPictureOfTheDayAttribution_) {
        [self hideAttributionLabel];
        return;
    }
    
    [self setTextInputFocusOnEmptyField];
}

-(void)handleSwipeUp
{
    if (showingPictureOfTheDayAttribution_) return;
    [self setTextInputFocusOnEmptyField];
}

-(void)handleSwipeDown
{
    if (showingPictureOfTheDayAttribution_){
        [self hideAttributionLabel];
        return;
    }
    [self hideKeyboard];
}

-(void)handleSwipeLeft
{
    if (self.currentUserButton.hidden) return;
    
    [self showMyUploadsVC];
}

-(void)handleLongPress
{
    // Uncomment for presentation username/pwd auto entry
    /*
     self.usernameField.text = @"";
     self.passwordField.text = @"";
     
     [self fadeLoginButtonIfNoCredentials];
     */
}

-(void)handleDoubleTap
{
    // Hide the keyboard. Needed because on non-iPad keyboard there is no hide keyboard button
    [self hideKeyboard];
}

#pragma mark - Text field delegate methods

/**
 * Advance text field to text field with next tag.
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
    NSInteger nextTag = textField.tag + 1;

    UIResponder *nextResponder = [textField.superview viewWithTag:nextTag];
    if (nextResponder) {
        [nextResponder becomeFirstResponder];
    } else if (textField != self.passwordField) {
        [textField resignFirstResponder];
    }
    
    if (textField == self.passwordField) {
        [self pushedLoginButton:textField];
    }

    return NO;
}

#pragma mark - KVO

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if ([keyPath isEqualToString:@"text"]) {
        [self showPlaceHolderTextIfNecessary];
    }
}

@end
