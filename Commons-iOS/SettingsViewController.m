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
}

@property (weak, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *browserAndDebugContainersTopConstraint;

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

    [self constrainSubviews];

    // The debug settings toggle is hidden by default unless the settings screen is tapped 6 times
    [self setupDebugContainer];

    //[self.view randomlyColorSubviews];
}

-(void)constrainSubviews
{
    void (^constrainButton)(UIButton *) = ^(UIButton *button){
        // Add left and right padding
        float padding = 12.0f;
        button.titleEdgeInsets = UIEdgeInsetsMake(0, padding, 0, padding);
        
        // Enable multi-line and word-wrapping
        button.titleLabel.numberOfLines = 0;
        button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        // Wrap button text at its present width constraint
        button.titleLabel.preferredMaxLayoutWidth = button.frame.size.width;
        
        // Size the button's height to be the size of its text plus padding
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem: button
                                                              attribute: NSLayoutAttributeHeight
                                                              relatedBy: NSLayoutRelationEqual
                                                                 toItem: button.titleLabel
                                                              attribute: NSLayoutAttributeHeight
                                                             multiplier: 1.0f
                                                               constant: padding * 2.0f]];
    };
    
    constrainButton(self.commonsButton);
    constrainButton(self.privacyButton);
    constrainButton(self.bugsButton);
    constrainButton(self.thisAppContributorsButton);
    constrainButton(self.thisAppLicenseButton);
    constrainButton(self.thisAppSourceButton);
    constrainButton(self.gradientButtonLicenseButton);
    constrainButton(self.gradientButtonSourceButton);

    UIColor *color = [UIColor colorWithWhite:1.0f alpha:0.1f];
    self.thisAppContributorsButton.backgroundColor = color;
    self.thisAppLicenseButton.backgroundColor = color;
    self.thisAppSourceButton.backgroundColor = color;
    self.gradientButtonLicenseButton.backgroundColor = color;
    self.gradientButtonSourceButton.backgroundColor = color;

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
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Round just the top left and bottom left corners of openInLabel
    [app_ roundCorners:UIRectCornerTopLeft|UIRectCornerBottomLeft ofView:self.openInLabel toRadius:10.0];
    [self.view setNeedsLayout];
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
    [self.externalBrowserContainer.superview removeConstraint:self.spaceBetweenDebugAndBrowserContainersConstraint];
    [self.externalBrowserContainer.superview addConstraint:self.browserAndDebugContainersTopConstraint];
    self.debugInfoContainer.alpha = 0.0f;
}

-(void)showDebugContainer
{
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

#pragma mark - Positioning

-(void)viewWillLayoutSubviews
{
    // Resize browsersTableView according to its number of rows
    [self adjustHeightOfBrowsersTableView];

    // Style buttons with rounded corners - needs to happen in viewWillLayoutSubviews
    // because autolayout may have changed the frame of the buttons
    [self applyStyleToButton:self.commonsButton];
    [self applyStyleToButton:self.privacyButton];
    [self applyStyleToButton:self.bugsButton];
}

-(void)moveOpenInLabelBesideSelectedBrowserCell:(UITableViewCell *)cell
{
    // Animate the openInLabel from its present vertical position to a position vertically
    // aligned with browsersTableView's selected cell
    [UIView animateWithDuration:0.25
						  delay:0.0
						options:UIViewAnimationOptionTransitionNone
					 animations:^{

					     self.openInLabel.backgroundColor = [UIColor lightGrayColor];

                         // Account for browsersTableView's contentOffset
                         float cellY = [self.browsersTableView rectForRowAtIndexPath:self.browsersTableView.indexPathForSelectedRow].origin.y;

                         cellY -= self.browsersTableView.contentOffset.y;
                         cellY += self.browsersTableView.frame.origin.y;
                         
                         // Set label frame shifting it into the same vertical position as the selected cell
                         // Also make the label the same height as the cell
                         self.openInLabel.frame = CGRectMake(self.openInLabel.frame.origin.x,
                                                             cellY,
                                                             self.openInLabel.frame.size.width,
                                                             self.openInLabel.frame.size.height);
                     }
					 completion:^(BOOL finished){
                         // Determine cell height so label can be made to be same height
                         float cellHeight = cell.frame.size.height;

                         // Set label frame shifting it into the same vertical position as the selected cell
                         // Also make the label the same height as the cell
                         self.openInLabel.frame = CGRectMake(self.openInLabel.frame.origin.x,
                                                             self.openInLabel.frame.origin.y,
                                                             self.openInLabel.frame.size.width,
                                                             cellHeight);
                     }];
}

- (void)moveSelectedBrowserToTop
{
    // Make the user's browser choice appear at the top of the list when the view appears by moving
    // their choice to the front of the installedSupportedBrowserNames array
    if (installedSupportedBrowserNames_.count > 1) {
        NSString *defaultExternalBrowser = app_.defaultExternalBrowser;
        NSUInteger selectedBrowserIndex = [installedSupportedBrowserNames_ indexOfObject:defaultExternalBrowser];
        if (selectedBrowserIndex != NSNotFound) {
            // Remove the selected browser from the array and re-add it to the front of
            // the array. Was swapping the selected entry with the first entry but this caused
            // the alpha sort of the items after the first to be messed up
            NSString *selectedBrowser = [installedSupportedBrowserNames_ objectAtIndex:selectedBrowserIndex];
            [installedSupportedBrowserNames_ removeObjectAtIndex:selectedBrowserIndex];
            [installedSupportedBrowserNames_ insertObject:selectedBrowser atIndex:0];
        }
    }
}

-(void)hideDebugInfoContainerIfReleaseBuild
{
    self.debugInfoContainer.hidden = YES;
}

#pragma mark - Styling

-(void)applyStyleToButton:(UIButton *) button
{
    // Button must have it's type set to "Custom" in interface builder for these
    // settings to take effect
    button.layer.backgroundColor = [UIColor colorWithRed:0.08 green:0.50 blue:0.92 alpha:0.9].CGColor;
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [app_ roundCorners:UIRectCornerAllCorners ofView:button toRadius:10.0];
}

-(void)useLastPicOfDayShownByLoginPageAsBackground
{
    UIImageView *potdImageView_ = (UIImageView *)((LoginViewController *)self.navigationController.viewControllers[0]).potdImageView;
    settingsImageView_.contentMode = potdImageView_.contentMode;
    settingsImageView_.image = potdImageView_.image;
    [settingsImageView_ prepareFilteredImage];
    [settingsImageView_ toFiltered];
    [settingsImageView_ zoom];
}

#pragma mark - Sizing

- (void)adjustHeightOfBrowsersTableView
{
    if (self.browsersTableView.contentSize.height == 0.0f) return;
    self.browsersTableViewHeightConstraint.constant = self.browsersTableView.contentSize.height;
}

#pragma mark - Browser selection table view

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Moved the initialization of installedSupportedBrowserNames to "tableView:numberOfRowsInSection:"
    // because it's former location in "viewWillAppear:" didn't always execute before
    // "tableView:numberOfRowsInSection:".
    // See the following for more details: http://stackoverflow.com/a/6391136/135557
 
    // Get array of supported browsers which are installed on the device
    installedSupportedBrowserNames_ = [[browserHelper_ getInstalledSupportedBrowserNames] mutableCopy];

    [self moveSelectedBrowserToTop];
    
    return [installedSupportedBrowserNames_ count];
}

- (void)receivedUIApplicationDidBecomeActiveNotification:(NSNotification *)notification
{
    // Ensure response to UIApplicationDidBecomeActiveNotification's only if this view is visible
    if(self.navigationController.topViewController == self){

        // Update the list of browsers in case the user deleted one while the app was suspended
        installedSupportedBrowserNames_ = [[browserHelper_ getInstalledSupportedBrowserNames] mutableCopy];
        
        [self moveSelectedBrowserToTop];
              
        [self.browsersTableView reloadData];
        
        [self.view setNeedsLayout];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([cell.textLabel.text isEqualToString:app_.defaultExternalBrowser]) cell.selected = YES;
    
    [self moveOpenInLabelBesideSelectedBrowserCell:cell];
    
    // Round just the top right and bottom right corners of the cell
    [app_ roundCorners:UIRectCornerTopRight|UIRectCornerBottomRight ofView:cell toRadius:10.0];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"BrowserTableItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
        
    // Make the cell use the same font as openInLabel so they look consistent
    cell.textLabel.font = self.openInLabel.font;
    
    // Make the cell display the browser name
    cell.textLabel.text = [installedSupportedBrowserNames_ objectAtIndex:indexPath.row];

    cell.textLabel.textColor = [UIColor whiteColor];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [self.browsersTableView cellForRowAtIndexPath:indexPath];
    app_.defaultExternalBrowser = selectedCell.textLabel.text;
    
    // Ensure previous selection highlighting turns off. Not sure why this is needed...
    for (UITableViewCell *cell in self.browsersTableView.visibleCells) {
        if (cell != selectedCell) cell.selected = NO;
    }
    
    [self moveOpenInLabelBesideSelectedBrowserCell:selectedCell];

    // If only Safari is installed and the user taps "Safari" remind them why they're not seeing other browsers
    if ([installedSupportedBrowserNames_ count] == 1) {

        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[MWMessage forKey:@"settings-open-links-only-safari"].text
                                                            message:nil
                                                           delegate:nil
                                                  cancelButtonTitle:[MWMessage forKey:@"error-dismiss"].text
                                                  otherButtonTitles:nil];
        [alertView show];
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
