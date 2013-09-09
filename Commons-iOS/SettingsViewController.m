//
//  SettingsViewController.m
//  Commons-iOS
//
//  Created by MONTE HURD on 4/5/13.

#import "SettingsViewController.h"
#import "CommonsApp.h"
#import "mwapi/MWApi.h"
#import "MWI18N/MWMessage.h"
#import "BrowserHelper.h"
#import <QuartzCore/QuartzCore.h>
#import "MyUploadsViewController.h"
#import "AppDelegate.h"
#import "LoadingIndicator.h"
#import "UILabel+ResizeWithAttributes.h"
#import "LoginViewController.h"
#import "SettingsImageView.h"
#import "UIView+Debugging.h"

#pragma mark - Defines

#define URL_DEBUG_MODE_TARGET_TESTING @"test.wikipedia.org"
#define URL_DEBUG_MODE_TARGET_COMMONS @"commons.wikimedia.org"

#define URL_COMMONS                   @"https://commons.wikimedia.org"
#define URL_BUGS                      @"https://bugzilla.wikimedia.org/buglist.cgi?product=Commons%20App"
#define URL_PRIVACY                   @"https://commons.wikimedia.org/wiki/Commons:Privacy_policy"

#define URL_THIS_APP_SOURCE           @"https://github.com/wikimedia/Commons-iOS"
#define URL_THIS_APP_LICENSE          @"https://raw.github.com/wikimedia/Commons-iOS/master/COPYING"
#define URL_THIS_APP_CONTRIBUTORS     @"https://github.com/wikimedia/Commons-iOS/contributors"

#define URL_GRADIENT_BUTTON_SOURCE    @"https://code.google.com/p/iphonegradientbuttons/"
#define URL_GRADIENT_BUTTON_LICENSE   @"http://opensource.org/licenses/mit-license.php"

#pragma mark - Private

@interface SettingsViewController ()
{
    NSMutableArray *installedSupportedBrowserNames_;
    BrowserHelper *browserHelper_;
    CommonsApp *app_;
    UIColor *navBarOriginalColor_;
    SettingsImageView *settingsImageView_;
    NSMutableArray *browserButtons_;
}

@property (weak, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSLayoutConstraint *browserAndDebugContainersTopConstraint;
@property (strong, nonatomic) NSLayoutConstraint *linksAndBrowserContainersTopConstraint;

@end

#pragma mark - Init

@implementation SettingsViewController

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        settingsImageView_ = [[SettingsImageView alloc] init];
        settingsImageView_.translatesAutoresizingMaskIntoConstraints = NO;
        
        browserHelper_ = [[BrowserHelper alloc] init];
        app_ = CommonsApp.singleton;
        installedSupportedBrowserNames_ = nil;
        browserButtons_ = [[NSMutableArray alloc] init];

        // Listen for UIApplicationDidBecomeActiveNotification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedUIApplicationDidBecomeActiveNotification:)
                                                     name:@"UIApplicationDidBecomeActiveNotification"
                                                   object:nil];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    self.settingsContainer.translatesAutoresizingMaskIntoConstraints = NO;

    // Ensure storyboard labels will wrap to multiple lines if necessary
    void(^multiLine)(UILabel *) = ^(UILabel *label){
        label.numberOfLines = 0;
        label.preferredMaxLayoutWidth = label.frame.size.width;
    };

    multiLine(self.trackingLabel);
    multiLine(self.trackingDetailsLabel);
    multiLine(self.externalLinksLabel);
    multiLine(self.uploadTargetLabel);
    multiLine(self.debugModeLabel);
    multiLine(self.openInLabel);
    multiLine(self.sourceLabel);
    multiLine(self.thisAppLabel);
    multiLine(self.gradientButtonsLabel);

    // Get the app delegate so the loading indicator may be accessed
	self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

	self.debugModeLabel.text = [MWMessage forKey:@"settings-debug-label"].text;
    self.navigationItem.title = [MWMessage forKey:@"settings-title"].text;
    self.openInLabel.text = [MWMessage forKey:@"settings-open-links-label"].text;
    self.trackingLabel.text = [MWMessage forKey:@"settings-usage-reports-label"].text;
    self.trackingDetailsLabel.text = [MWMessage forKey:@"settings-usage-reports-description"].text;
    self.externalLinksLabel.text = [MWMessage forKey:@"settings-links-label"].text;
    
    self.debugModeSwitch.on = app_.debugMode;
    [self setDebugModeLabel];
	   
    // Make settings switch reflect any saved value
    self.trackingSwitch.on = app_.trackingEnabled;
    
    // Get bundle info dict for its app name and version settings
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    
    // Set the app version label
    NSString *shortVersionString = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *versionText = [MWMessage forKey:@"about-app-version-label" param:shortVersionString].text;
    
    [self.appVersionLabel setText:versionText];

    [self.appVersionLabel resizeWithAttributes: @{
                          NSFontAttributeName : [UIFont boldSystemFontOfSize:27.0f],
               NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0f alpha:1.0f]
     } preferredMaxLayoutWidth:320.0f];

    // i18n for buttons
    [self.commonsButton setTitle:[MWMessage forKey:@"about-commons-button"].text forState:UIControlStateNormal];
    [self.bugsButton setTitle:[MWMessage forKey:@"about-bugs-button"].text forState:UIControlStateNormal];
    [self.privacyButton setTitle:[MWMessage forKey:@"about-privacy-button"].text forState:UIControlStateNormal];
    [self.sourceLabel setText:[MWMessage forKey:@"settings-source-label"].text];
    
    // i18n for the sub-items under the Source button
    [self.thisAppLabel setText:[MWMessage forKey:@"about-source-this-app-title"].text];
    [self.thisAppContributorsButton setTitle:[MWMessage forKey:@"about-source-this-app-contributors"].text forState:UIControlStateNormal];
    [self.thisAppSourceButton setTitle:[MWMessage forKey:@"about-source-button"].text forState:UIControlStateNormal];
    [self.thisAppLicenseButton setTitle:[MWMessage forKey:@"about-license-button"].text forState:UIControlStateNormal];
    
    [self.gradientButtonsLabel setText:[MWMessage forKey:@"about-source-gradient-title"].text];
    [self.gradientButtonSourceButton setTitle:[MWMessage forKey:@"about-source-button"].text forState:UIControlStateNormal];
    [self.gradientButtonLicenseButton setTitle:[MWMessage forKey:@"about-license-button"].text forState:UIControlStateNormal];
    
    self.sourceDetailsContainer.backgroundColor = [UIColor clearColor];

    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad){
        // Increase the space above the mock page a bit
        self.spaceAboveMockPageConstraint.constant *= 4.0f;
        // Scale the mock page down a bit
        CGAffineTransform xf = CGAffineTransformMakeScale(0.8f, 0.8f);
        self.mockPageContainerView.transform = xf;
    }else{
        // Increase the space above the mock page a bit
        self.spaceAboveMockPageConstraint.constant *= 6.0f;
        // Scale the mock page up a bit
        CGAffineTransform xf = CGAffineTransformMakeScale(1.45f, 1.45f);
        self.mockPageContainerView.transform = xf;
    }

    // Add the image view for the picture of the day last shown by the login page
    [self.view insertSubview:settingsImageView_ atIndex:0];

    UIColor *color = [UIColor colorWithWhite:1.0f alpha:0.1f];
    self.thisAppContributorsButton.backgroundColor = color;
    self.thisAppLicenseButton.backgroundColor = color;
    self.thisAppSourceButton.backgroundColor = color;
    self.gradientButtonLicenseButton.backgroundColor = color;
    self.gradientButtonSourceButton.backgroundColor = color;
    self.commonsButton.backgroundColor = color;
    self.privacyButton.backgroundColor = color;
    self.bugsButton.backgroundColor = color;

    [self constrainSubviews];

    // The debug settings toggle is hidden by default unless the settings screen is tapped 6 times
    [self setupDebugContainer];

    // The browser settings are hidden unless more than one browser is found
    [self setupBrowserContainer];

    // Add and constrain a button for each browser installed on the device
    [self updateBrowserButtons];

    //[self.view randomlyColorSubviews];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    navBarOriginalColor_ = self.navigationController.navigationBar.backgroundColor;
    [self.navigationController.navigationBar setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.65f]];

    [self useLastPicOfDayShownByLoginPageAsBackground];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.navigationController.navigationBar setBackgroundColor:navBarOriginalColor_];

    MyUploadsViewController *myUploadsViewController = [self getMyUploadsViewController];
    
    [app_ fetchUploadRecords];
    
    [myUploadsViewController.collectionView reloadData];
    
    [myUploadsViewController.collectionView.collectionViewLayout invalidateLayout];
}

#pragma mark - Constraints

-(void)constrainButtonHeight:(UIButton *)button
{
    // Add left and right padding
    float padding = 12.0f;
    button.titleEdgeInsets = UIEdgeInsetsMake(0, padding, 0, padding);
    
    // Enable multi-line and word-wrapping
    button.titleLabel.numberOfLines = 0;
    button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    // Wrap button text at its present width constraint
    button.titleLabel.preferredMaxLayoutWidth = button.frame.size.width;
    
    // Size the button's height to be the size of its text plus padding
    [button.superview addConstraint:[NSLayoutConstraint constraintWithItem: button
                                                                 attribute: NSLayoutAttributeHeight
                                                                 relatedBy: NSLayoutRelationEqual
                                                                    toItem: button.titleLabel
                                                                 attribute: NSLayoutAttributeHeight
                                                                multiplier: 1.0f
                                                                  constant: padding * 2.0f]];
    
}

-(void)constrainSubviews
{
    [self constrainButtonHeight:self.commonsButton];
    [self constrainButtonHeight:self.privacyButton];
    [self constrainButtonHeight:self.bugsButton];
    [self constrainButtonHeight:self.thisAppContributorsButton];
    [self constrainButtonHeight:self.thisAppLicenseButton];
    [self constrainButtonHeight:self.thisAppSourceButton];
    [self constrainButtonHeight:self.gradientButtonLicenseButton];
    [self constrainButtonHeight:self.gradientButtonSourceButton];

    void(^constrainSettingsImageView)(NSString *) = ^(NSString *vfString){
        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat: vfString
                                   options:  0
                                   metrics:  @{@"margin" : @(0)}
                                   views:    @{@"settingsImageView" : settingsImageView_}
                                   ]];
    };
    constrainSettingsImageView(@"H:|[settingsImageView]|");
    constrainSettingsImageView(@"V:|[settingsImageView]|");
    
    // This is used when toggling the visibility of the debug container
    self.browserAndDebugContainersTopConstraint = [NSLayoutConstraint constraintWithItem:self.externalBrowserContainer
                                                      attribute:NSLayoutAttributeTop
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:self.debugInfoContainer
                                                      attribute:NSLayoutAttributeTop
                                                     multiplier:1.0
                                                       constant:0];

    // This is used when toggling the visibility of the browser container
    self.linksAndBrowserContainersTopConstraint = [NSLayoutConstraint constraintWithItem:self.externalLinksContainer
                                                      attribute:NSLayoutAttributeTop
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:self.externalBrowserContainer
                                                      attribute:NSLayoutAttributeTop
                                                     multiplier:1.0
                                                       constant:0];
}

#pragma mark - Debug container

-(void)setupDebugContainer
{
    // Make the debug container be hidden initially
    [self hideDebugContainer];

    // Add tap gesture for revealing the debug container if view tapped a number of times
    UITapGestureRecognizer *doubleTapRecognizer_ = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleDebugContainer)];
    doubleTapRecognizer_.numberOfTapsRequired = 6;
    [self.view addGestureRecognizer:doubleTapRecognizer_];
    doubleTapRecognizer_.enabled = YES;
}

-(void)hideDebugContainer
{
    if (self.debugInfoContainer.alpha == 0.0f) return;
    [self.externalBrowserContainer.superview removeConstraint:self.spaceBetweenDebugAndBrowserContainersConstraint];
    [self.externalBrowserContainer.superview addConstraint:self.browserAndDebugContainersTopConstraint];
    self.debugInfoContainer.alpha = 0.0f;
}

-(void)showDebugContainer
{
    if (self.debugInfoContainer.alpha == 1.0f) return;
    [self.externalBrowserContainer.superview removeConstraint:self.browserAndDebugContainersTopConstraint];
    [self.externalBrowserContainer.superview addConstraint:self.spaceBetweenDebugAndBrowserContainersConstraint];
    self.debugInfoContainer.alpha = 1.0f;
}

-(void)toggleDebugContainer
{
    [UIView animateWithDuration:0.2f
                          delay:0.0f
                        options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         if (self.debugInfoContainer.alpha == 1.0f) {
                             [self hideDebugContainer];
                         }else{
                             [self showDebugContainer];
                         }
                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished){
                     }];
}

#pragma mark - Styling

-(void)useLastPicOfDayShownByLoginPageAsBackground
{
    UIImageView *potdImageView_ = (UIImageView *)((LoginViewController *)self.navigationController.viewControllers[0]).potdImageView;
    settingsImageView_.contentMode = potdImageView_.contentMode;
    settingsImageView_.image = potdImageView_.image;
    [settingsImageView_ prepareFilteredImage];
    [settingsImageView_ toFiltered];
    [settingsImageView_ zoom];
}

#pragma mark - Browser container

-(void)setupBrowserContainer
{
    [self hideBrowserContainer];
}

-(void)hideBrowserContainer
{
    if (self.externalBrowserContainer.alpha == 0.0f) return;
    [self.externalBrowserContainer.superview removeConstraint:self.spaceBetweenBrowserAndLinksContainersConstraint];
    [self.externalBrowserContainer.superview addConstraint:self.linksAndBrowserContainersTopConstraint];
    self.externalBrowserContainer.alpha = 0.0f;
}

-(void)showBrowserContainer
{
    if (self.externalBrowserContainer.alpha == 1.0f) return;
    [self.externalBrowserContainer.superview removeConstraint:self.linksAndBrowserContainersTopConstraint];
    [self.externalBrowserContainer.superview addConstraint:self.spaceBetweenBrowserAndLinksContainersConstraint];
    self.externalBrowserContainer.alpha = 1.0f;
}

#pragma mark - Browser buttons

-(void) updateBrowserButtons
{
    installedSupportedBrowserNames_ = [[browserHelper_ getInstalledSupportedBrowserNames] mutableCopy];

    // For simulator debuggin fake out a couple browsers
    //[installedSupportedBrowserNames_ addObject:@"Chrome"];
    //[installedSupportedBrowserNames_ addObject:@"Opera"];

    // Remove any existing browser buttons so this code may be recalled to refresh the buttons
    for (UIView *button in browserButtons_) {
        [button removeConstraints:button.constraints];
        [button removeFromSuperview];
    }
    [browserButtons_ removeAllObjects];
    
    // Make and constrain a button for each browser
    for (NSString *browserName in installedSupportedBrowserNames_) {

        UIButton *button = [[UIButton alloc] init];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [button.titleLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
        button.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.1f];
        button.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:1.0f].CGColor;

        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [button setTitle:browserName forState:UIControlStateNormal];
        
        [self setBrowserButtonSelectionIndication:button];

        [button addTarget:self action:@selector(browserSelected:) forControlEvents:UIControlEventTouchUpInside];

        [browserButtons_ addObject:button];
        
        [self.externalBrowserContainer addSubview:button];
    }
    
    [self constrainBrowserButtons];

    // If only Safari is present don't show the browser chooser. No need.
    if (browserButtons_.count > 1) {
        [self showBrowserContainer];
    }else{
        [self hideBrowserContainer];
    }
}

-(void)constrainBrowserButtons
{
    UIButton *previousButton = nil;
    for (UIButton *button in browserButtons_) {
        // Constrain the button width to 280
        [self.externalBrowserContainer addConstraints: [NSLayoutConstraint
                                                        constraintsWithVisualFormat: @"H:[button(==280)]"
                                                        options:  0
                                                        metrics:  nil
                                                        views:    @{@"button" : button}
                                                        ]];
        
        // Constrain the button center to its superview center
        [self.externalBrowserContainer addConstraint:[NSLayoutConstraint
                                                      constraintWithItem:button
                                                      attribute:NSLayoutAttributeCenterX
                                                      relatedBy:NSLayoutRelationEqual
                                                      toItem:self.externalBrowserContainer
                                                      attribute:NSLayoutAttributeCenterX
                                                      multiplier:1.0
                                                      constant:0]];
        
        // Make the button's height vary with any text it is displaying
        [self constrainButtonHeight:button];

        // Constrain the vertical space between buttons
        if (previousButton) {
            [self.externalBrowserContainer addConstraints: [NSLayoutConstraint
                                                            constraintsWithVisualFormat: @"V:[previousButton]-[button]"
                                                            options:  0
                                                            metrics:  nil
                                                            views:    @{@"button" : button, @"previousButton" : previousButton}
                                                            ]];
        }
        previousButton = button;
    }
    
    // Constrain the vertical space between the first button and the openInLabel
    [self.externalBrowserContainer addConstraints: [NSLayoutConstraint
                                                    constraintsWithVisualFormat: @"V:[openInLabel]-[firstButton]"
                                                    options:  0
                                                    metrics:  nil
                                                    views:    @{@"firstButton" : [browserButtons_ firstObject], @"openInLabel" : self.openInLabel}
                                                    ]];
    // Constrain the vertical space between the last button and the superview
    [self.externalBrowserContainer addConstraints: [NSLayoutConstraint
                                                    constraintsWithVisualFormat: @"V:[lastButton]-|"
                                                    options:  0
                                                    metrics:  nil
                                                    views:    @{@"lastButton" : [browserButtons_ lastObject]}
                                                    ]];

}

-(void)browserSelected:(id)sender
{
    UIButton *tappedButton = (UIButton *)sender;
    app_.defaultExternalBrowser = tappedButton.titleLabel.text;
    
    for (UIButton *button in browserButtons_) {
        [self setBrowserButtonSelectionIndication:button];
    }
}

-(void)setBrowserButtonSelectionIndication:(UIButton *)button
{
    if (
        [button.titleLabel.text isEqualToString:app_.defaultExternalBrowser]
        &&
        ([installedSupportedBrowserNames_ count] > 1))
    {
        button.layer.borderWidth = 1.0f;
    }else{
        button.layer.borderWidth = 0.0f;
    }
}

- (void)receivedUIApplicationDidBecomeActiveNotification:(NSNotification *)notification
{
    // Ensure response to UIApplicationDidBecomeActiveNotification's only if this view is visible
    if(self.navigationController.topViewController == self){
        [self updateBrowserButtons];
        [self.view layoutIfNeeded];
    }
}

#pragma mark - Debug switch

-(MyUploadsViewController *) getMyUploadsViewController
{
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc isMemberOfClass:[MyUploadsViewController class]]) {
            return (MyUploadsViewController *)vc;
        }
    }
    return nil;
}

- (IBAction)debugSwitchPushed:(id)sender
{
    // Cancel any fetches as they won't be relevant
    [app_.fetchDataURLQueue cancelAllOperations];
    
    app_.debugMode = self.debugModeSwitch.on;
    [self setDebugModeLabel];
    
    [app_ deleteAllRecords];

    // Show the loading indicator wheel
    // Needed because the user may have a large list of images and if they back up to the MyUploads page
    // before the data is in place for the MyUploads page it will crash
    [self.appDelegate.loadingIndicator show];
    
    MWPromise *refresh = [app_ refreshHistoryWithFailureAlert:NO];
    [refresh always:^(id arg) {
        // Show the loading indicator wheel
        [self.appDelegate.loadingIndicator hide];
        
        // Reset the fetchedResultsController delegate
        app_.fetchedResultsController.delegate = [self getMyUploadsViewController];
    }];
}

- (void)setDebugModeLabel
{
    NSString *target;
    if (app_.debugMode) {
        target = URL_DEBUG_MODE_TARGET_TESTING;
    } else {
        target = URL_DEBUG_MODE_TARGET_COMMONS;
    }
    self.uploadTargetLabel.text = [MWMessage forKey:@"settings-debug-detail" params:@[target]].text;
}

#pragma mark - Logging switch

- (IBAction)loggingSwitchPushed:(id)sender
{
    // Log the logging preference change
	[app_ log:@"MobileAppTrackingChange" event:@{
     @"state": self.trackingSwitch.on ? @YES : @NO
     } override:YES];
    
    // Now set logging according to switch
    app_.trackingEnabled = self.trackingSwitch.on;
}

#pragma mark - External links

-(IBAction)openURLinExternalBrowser:(id)sender
{
    // Detect which button was tapped and open its URL in external browser
    
    // Ensure the button doesn't remain in highlighted state
    if ([sender isKindOfClass:[UIButton class]]) {
        [sender setHighlighted:NO];
    }
    
    // Determine the target url based on which button was tapped
    
    NSString *urlStr = nil;
    
    if (sender == self.commonsButton) {
        
        urlStr = URL_COMMONS;
        
    }else if (sender == self.bugsButton) {
        
        urlStr = URL_BUGS;
        
    }else if (sender == self.privacyButton) {
        
        urlStr = URL_PRIVACY;
        
    }else if (sender == self.thisAppContributorsButton) {
        
        urlStr = URL_THIS_APP_CONTRIBUTORS;
        
    }else if (sender == self.thisAppSourceButton) {
        
        urlStr = URL_THIS_APP_SOURCE;
        
    }else if (sender == self.thisAppLicenseButton) {
        
        urlStr = URL_THIS_APP_LICENSE;
        
    }else if (sender == self.gradientButtonSourceButton) {
        
        urlStr = URL_GRADIENT_BUTTON_SOURCE;
        
    }else if (sender == self.gradientButtonLicenseButton) {
        
        urlStr = URL_GRADIENT_BUTTON_LICENSE;
    }
    
    // Open the url in the user's preferred browser
    if (urlStr) [app_ openURLWithDefaultBrowser:[NSURL URLWithString:urlStr]];    
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
