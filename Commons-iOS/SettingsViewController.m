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
#import "GradientButton.h"

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
}

-(void)moveOpenInLabelBesideSelectedBrowserCell:(UITableViewCell *)cell;
-(void)roundCorners:(UIRectCorner)corners ofView:(UIView *)view toRadius:(float)radius;
-(void)moveSelectedBrowserToTop;
-(MyUploadsViewController *) getMyUploadsViewController;

- (void)toggleSourceDetailsContainerVisibility;
- (void)scrollToBottomOfExternalLinksContainer;

@property (weak, nonatomic) AppDelegate *appDelegate;

@end

#pragma mark - Init

@implementation SettingsViewController

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
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

#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	    
    // Get the app delegate so the loading indicator may be accessed
	self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

	self.debugModeLabel.text = [MWMessage forKey:@"settings-debug-label"].text;
    self.navigationItem.title = [MWMessage forKey:@"settings-title"].text;
    self.openInLabel.text = [MWMessage forKey:@"settings-open-links-label"].text;
    self.trackingLabel.text = [MWMessage forKey:@"settings-usage-reports-label"].text;
    self.trackingDetailsLabel.text = [MWMessage forKey:@"settings-usage-reports-description"].text;
    self.externalLinksLabel.text = [MWMessage forKey:@"settings-links-label"].text;
    
    self.openInLabel.adjustsFontSizeToFitWidth = YES;
    
    self.debugModeSwitch.on = app_.debugMode;
    [self setDebugModeLabel];
	    
    self.externalLinksContainer.alpha = 0.0f;
    
    // Set the content size of the scrollView
    self.scrollView.contentSize = self.settingsContainer.frame.size;
    
    // Make settings switch reflect any saved value
    self.trackingSwitch.on = app_.trackingEnabled;
    
    // Get bundle info dict for its app name and version settings
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];

    // Set the app name label
    NSString *appDisplayName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    [self.appNameLabel setText:appDisplayName];
    
    // Set the app version label
    NSString *shortVersionString = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *versionText = [MWMessage forKey:@"about-app-version-label" param:shortVersionString].text;
    
    [self.appVersionLabel setText:versionText];
    
    // Set gradient button color scheme
    [self.sourceButton useBlackActionSheetStyle];
    [self.commonsButton useBlackActionSheetStyle];
    [self.bugsButton useBlackActionSheetStyle];
    [self.privacyButton useBlackActionSheetStyle];
    
    // Ensure button text doesn't get clipped if i18n is long string
    self.sourceButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.commonsButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.bugsButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.privacyButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    // i18n for buttons
    [self.commonsButton setTitle:[MWMessage forKey:@"about-commons-button"].text forState:UIControlStateNormal];
    [self.bugsButton setTitle:[MWMessage forKey:@"about-bugs-button"].text forState:UIControlStateNormal];
    [self.privacyButton setTitle:[MWMessage forKey:@"about-privacy-button"].text forState:UIControlStateNormal];
    [self.sourceButton setTitle:[MWMessage forKey:@"about-source-button"].text forState:UIControlStateNormal];
    
    // i18n for the sub-items under the Source button
    [self.thisAppLabel setText:[MWMessage forKey:@"about-source-this-app-title"].text];
    [self.thisAppContributorsButton setTitle:[MWMessage forKey:@"about-source-this-app-contributors"].text forState:UIControlStateNormal];
    [self.thisAppSourceButton setTitle:[MWMessage forKey:@"about-source-button"].text forState:UIControlStateNormal];
    [self.thisAppLicenseButton setTitle:[MWMessage forKey:@"about-license-button"].text forState:UIControlStateNormal];
    
    [self.gradientButtonsLabel setText:[MWMessage forKey:@"about-source-gradient-title"].text];
    [self.gradientButtonSourceButton setTitle:[MWMessage forKey:@"about-source-button"].text forState:UIControlStateNormal];
    [self.gradientButtonLicenseButton setTitle:[MWMessage forKey:@"about-license-button"].text forState:UIControlStateNormal];
}

- (void)revealExternalLinksContainerBelowBrowsersTableView
{
    CGRect externalLinksContainerFrame = self.externalLinksContainer.frame;
    float top = self.externalBrowserContainer.frame.origin.y;
    top += self.browsersTableView.frame.origin.y;
    top += self.browsersTableView.frame.size.height;
    
    // If there's only one browser add a little padding
    if ([self.browsersTableView numberOfRowsInSection:0] < 2) top += 15.0f;
    
    externalLinksContainerFrame.origin.y = top;
    self.externalLinksContainer.frame = externalLinksContainerFrame;
    
    [UIView animateWithDuration:0.1 animations:^{
        self.externalLinksContainer.alpha = 1.0f;
    }];
}

- (void)adjustHeightOfBrowsersTableView
{
    CGRect browsersTableViewFrame = self.browsersTableView.frame;
    browsersTableViewFrame.size.height = self.browsersTableView.contentSize.height;
    self.browsersTableView.frame = browsersTableViewFrame;
}

-(void)viewDidAppear:(BOOL)animated
{
    // Round just the top left and bottom left corners of openInLabel
    [self roundCorners:UIRectCornerTopLeft|UIRectCornerBottomLeft ofView:self.openInLabel toRadius:10.0];
    
    // Resize browsersTableView according to its number of rows
    [self adjustHeightOfBrowsersTableView];
    // Now that browsersTableView has been resized, move the link buttons below the browsersTableView
    [self revealExternalLinksContainerBelowBrowsersTableView];
    
    [super viewDidAppear:animated];
}

- (void)viewDidUnload {
    [self setDebugModeSwitch:nil];
    [self setDebugModeLabel:nil];
	[self setUploadTargetLabel:nil];
    
    [super viewDidUnload];
}

-(void)roundCorners:(UIRectCorner)corners ofView:(UIView *)view toRadius:(float)radius
{   // Use for rounding *specific* corners of a UIView.
    // Based on http://stackoverflow.com/a/5826745/135557

    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:view.bounds
                                                   byRoundingCorners:corners
                                                         cornerRadii:CGSizeMake(radius, radius)];
    // Create the shape layer and set its path
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = view.bounds;
    maskLayer.path = maskPath.CGPath;
    
    // Set the newly created shape layer as the mask for the image view's layer
    view.layer.mask = maskLayer;
}

-(void)viewDidLayoutSubviews
{
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad){
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
            // If orientation is landscape...
            if(self.sourceDetailsContainer.alpha != 0.0){
                // If source details are visible so scroll all the way to the bottom so all of the details may be seen
                [self scrollToBottomOfExternalLinksContainer];
            }else{
                [self scrollToBottomOfDebugInfoContainer];
            }
        }else{
            // If orientation is portrait just scroll to the top
            [self scrollToTopOfSettingsContainer];
        }
    }
}

-(void)scrollToBottomOfDebugInfoContainer
{
    [self.scrollView scrollRectToVisible:CGRectMake(0, self.debugInfoContainer.frame.origin.y + self.debugInfoContainer.frame.size.height + 10, 1, 1) animated:YES];
}

-(void)scrollToBottomOfSettingsContainer
{
    [self.scrollView scrollRectToVisible:CGRectMake(0, self.scrollView.contentSize.height - 1, 1, 1) animated:YES];
}

-(void)scrollToTopOfSettingsContainer
{
    // Scroll to the top of the settingsContainer
    [self.scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}

#pragma mark - Browser Selection Table View

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
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([cell.textLabel.text isEqualToString:app_.defaultExternalBrowser]) cell.selected = YES;
    
    [self moveOpenInLabelBesideSelectedBrowserCell:cell];
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
    
    // Round just the top right and bottom right corners of the cell
    [self roundCorners:UIRectCornerTopRight|UIRectCornerBottomRight ofView:cell toRadius:10.0];

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
                         
                         // Determine cell height so label can be made to be same height
                         float cellHeight = cell.frame.size.height;
                         
                         // Set label frame shifting it into the same vertical position as the selected cell
                         // Also make the label the same height as the cell
                         self.openInLabel.frame = CGRectMake(self.openInLabel.frame.origin.x, cellY, self.openInLabel.frame.size.width, cellHeight);
                     }
					 completion:^(BOOL finished){
                         
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

#pragma mark - Debug Switch

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

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    MyUploadsViewController *myUploadsViewController = [self getMyUploadsViewController];
    
    [app_ fetchUploadRecords];
    
    [myUploadsViewController.collectionView reloadData];
    
    [myUploadsViewController.collectionView.collectionViewLayout invalidateLayout];
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

#pragma mark - Logging Switch

- (IBAction)loggingSwitchPushed:(id)sender
{
    // Log the logging preference change
	[app_ log:@"MobileAppTrackingChange" event:@{
     @"state": self.trackingSwitch.on ? @YES : @NO
     } override:YES];
    
    // Now set logging according to switch
    app_.trackingEnabled = self.trackingSwitch.on;
}

#pragma mark - External Links methods (From old About page)

-(void)scrollToBottomOfExternalLinksContainer
{
    // Scroll to the bottom of the externalLinksContainer. OK to use self.scrollView.contentSize as it is set
    // to self.externalLinksContainer.frame.size in the viewDidLoad
    // (The rect passed to scrollRectToVisible must have its origin.y be less than self.scrollView.contentSize.height
    // or it won't scroll, hence the "- 1")
    [self.scrollView scrollRectToVisible:CGRectMake(0, self.scrollView.contentSize.height - 1, 1, 1) animated:YES];
}

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

-(void)toggleSourceDetailsContainerVisibility
{
    CGRect sourceDetailsContainerStoryboardFrame = self.sourceDetailsContainer.frame;
    
    // This offset determines how far the details container will be moved up or down during the show or hide
    float offscreenFrameOffset = 110.0;
    
    if(self.sourceDetailsContainer.alpha == 0.0){
        // If the container is presently hidden, nudge it off the bottom of the screen so the show animation
        // can slide it back up into place. Nice as it's all relative to the container's storyboard position
        // so storyboard adjustments won't break the animation as movement is relative
        self.sourceDetailsContainer.frame = CGRectOffset(self.sourceDetailsContainer.frame, 0.0, offscreenFrameOffset);
    }
    
    [UIView animateWithDuration:0.25
						  delay:0.0
						options:UIViewAnimationOptionTransitionNone
					 animations:^{
                         if(self.sourceDetailsContainer.alpha == 1.0){
                             // If container is visible fade out alpha and move it offscreen
                             self.sourceDetailsContainer.alpha = 0.0;
                             self.sourceDetailsContainer.frame = CGRectOffset(self.sourceDetailsContainer.frame, 0.0, offscreenFrameOffset);
                         }else{
                             // If container is hidden fade in alpha and move it onscreen
                             self.sourceDetailsContainer.alpha = 1.0;
                             self.sourceDetailsContainer.frame = sourceDetailsContainerStoryboardFrame;
                             
                             // Ensure the newly revealed sourceDetailsContainer is entirely on-screen
                             [self scrollToBottomOfExternalLinksContainer];
                         }
					 }
					 completion:^(BOOL finished){
                         // When done with either show or hide put the container back so everything is where it was and
                         // everything's in a good state for next toggle animation
                         self.sourceDetailsContainer.frame = sourceDetailsContainerStoryboardFrame;
					 }];
}

-(IBAction)sourceButtonTap:(id)sender
{
    [self.sourceButton setHighlighted:NO];
    
    [self toggleSourceDetailsContainerVisibility];
}


#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
