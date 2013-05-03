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

#pragma mark - Defines

#define URL_DEBUG_MODE_TARGET_TESTING @"test.wikipedia.org"
#define URL_DEBUG_MODE_TARGET_COMMONS @"commons.wikimedia.org"

#pragma mark - Private

@interface SettingsViewController ()
{
    NSMutableArray *installedSupportedBrowserNames;
    BrowserHelper *browserHelper;
    CommonsApp *app;
}

-(void)moveOpenInLabelBesideSelectedBrowserCell:(UITableViewCell *)cell;
-(void)roundCorners:(UIRectCorner)corners ofView:(UIView *)view toRadius:(float)radius;
-(void)moveSelectedBrowserToTop;
-(MyUploadsViewController *) getMyUploadsViewController;

@property (weak, nonatomic) AppDelegate *appDelegate;

@end

#pragma mark - Init

@implementation SettingsViewController

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        browserHelper = [[BrowserHelper alloc] init];
        app = CommonsApp.singleton;
        installedSupportedBrowserNames = nil;

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
    
    self.openInLabel.adjustsFontSizeToFitWidth = YES;
    
    self.debugModeSwitch.on = app.debugMode;
    [self setDebugModeLabel];
	    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        // On iPads add a little space above the logo to better center the scrollView
        UIEdgeInsets edgeInsets = UIEdgeInsetsMake(200, 0, 0, 0);
        [self.scrollView setContentInset:edgeInsets];
        [self.scrollView setScrollIndicatorInsets:edgeInsets];
    }
    
    // Set the content size of the scrollView
    self.scrollView.contentSize = self.settingsContainer.frame.size;
    
    // Make settings switch reflect any saved value
    self.trackingSwitch.on = app.trackingEnabled;
}

-(void)viewDidAppear:(BOOL)animated
{
    // Round just the top left and bottom left corners of openInLabel
    [self roundCorners:UIRectCornerTopLeft|UIRectCornerBottomLeft ofView:self.openInLabel toRadius:10.0];
    
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
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        // If orientation is landscape...
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
            [self scrollToBottomOfSettingsContainer];
        }else{
            [self scrollToBottomOfDebugInfoContainer];
        }
    }else{
        // If orientation is portrait just scroll to the top
        [self scrollToTopOfSettingsContainer];
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
    installedSupportedBrowserNames = [[browserHelper getInstalledSupportedBrowserNames] mutableCopy];

    [self moveSelectedBrowserToTop];
    
    return [installedSupportedBrowserNames count];
}

- (void)receivedUIApplicationDidBecomeActiveNotification:(NSNotification *)notification
{
    // Ensure response to UIApplicationDidBecomeActiveNotification's only if this view is visible
    if(self.navigationController.topViewController == self){

        // Update the list of browsers in case the user deleted one while the app was suspended
        installedSupportedBrowserNames = [[browserHelper getInstalledSupportedBrowserNames] mutableCopy];
        
        [self moveSelectedBrowserToTop];
              
        [self.browsersTableView reloadData];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([cell.textLabel.text isEqualToString:app.defaultExternalBrowser]) cell.selected = YES;
    
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
    cell.textLabel.text = [installedSupportedBrowserNames objectAtIndex:indexPath.row];
    
    // Round just the top right and bottom right corners of the cell
    [self roundCorners:UIRectCornerTopRight|UIRectCornerBottomRight ofView:cell toRadius:10.0];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [self.browsersTableView cellForRowAtIndexPath:indexPath];
    app.defaultExternalBrowser = selectedCell.textLabel.text;
    
    // Ensure previous selection highlighting turns off. Not sure why this is needed...
    for (UITableViewCell *cell in self.browsersTableView.visibleCells) {
        if (cell != selectedCell) cell.selected = NO;
    }
    
    [self moveOpenInLabelBesideSelectedBrowserCell:selectedCell];

    // If only Safari is installed and the user taps "Safari" remind them why they're not seeing other browsers
    if ([installedSupportedBrowserNames count] == 1) {

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
    if (installedSupportedBrowserNames.count > 1) {
        NSString *defaultExternalBrowser = app.defaultExternalBrowser;
        NSUInteger selectedBrowserIndex = [installedSupportedBrowserNames indexOfObject:defaultExternalBrowser];
        if (selectedBrowserIndex != NSNotFound) {
            // Remove the selected browser from the array and re-add it to the front of
            // the array. Was swapping the selected entry with the first entry but this caused
            // the alpha sort of the items after the first to be messed up
            NSString *selectedBrowser = [installedSupportedBrowserNames objectAtIndex:selectedBrowserIndex];
            [installedSupportedBrowserNames removeObjectAtIndex:selectedBrowserIndex];
            [installedSupportedBrowserNames insertObject:selectedBrowser atIndex:0];
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
    app.debugMode = self.debugModeSwitch.on;
    [self setDebugModeLabel];
    
    [app deleteAllRecords];

    // Show the loading indicator wheel
    // Needed because the user may have a large list of images and if they back up to the MyUploads page
    // before the data is in place for the MyUploads page it will crash
    [self.appDelegate.loadingIndicator show];
    
    MWPromise *refresh = [app refreshHistory];
    [refresh always:^(id arg) {
        // Show the loading indicator wheel
        [self.appDelegate.loadingIndicator hide];
        
        // Reset the fetchedResultsController delegate
        app.fetchedResultsController.delegate = [self getMyUploadsViewController];
    }];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    MyUploadsViewController *myUploadsViewController = [self getMyUploadsViewController];
    
    [app fetchUploadRecords];
    
    [myUploadsViewController.collectionView reloadData];
    
    [myUploadsViewController.collectionView.collectionViewLayout invalidateLayout];
}

- (void)setDebugModeLabel
{
    NSString *target;
    if (app.debugMode) {
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
	[app log:@"MobileAppTrackingChange" event:@{
        @"state": self.trackingSwitch.on ? @YES : @NO
    } override:YES];
    
    // Now set logging according to switch
    app.trackingEnabled = self.trackingSwitch.on;
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
