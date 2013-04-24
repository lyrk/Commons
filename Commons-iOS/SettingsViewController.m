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

-(void)moveOpenInLabelBesideSelectedBrowserCell;
-(void)roundCorners:(UIRectCorner)corners ofView:(UIView *)view toRadius:(float)radius;

@end

#pragma mark - Init

@implementation SettingsViewController


- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        browserHelper = [[BrowserHelper alloc] init];
        app = CommonsApp.singleton;

    }
    return self;
}

#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
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

-(void)viewWillAppear:(BOOL)animated
{
    // Get array of supported browsers which are installed on the device
    installedSupportedBrowserNames = [NSMutableArray arrayWithArray:[browserHelper getInstalledSupportedBrowserNames]];
    
    // Make the browser choice appear at the top of the list when the view appears
    if (installedSupportedBrowserNames.count > 1) {
        NSString *defaultExternalBrowser = app.defaultExternalBrowser;
        if (defaultExternalBrowser == nil) defaultExternalBrowser = @"Safari";
        NSUInteger selectedBrowserIndex = [installedSupportedBrowserNames indexOfObject:defaultExternalBrowser];
        if (selectedBrowserIndex != NSNotFound) {
            [installedSupportedBrowserNames exchangeObjectAtIndex:0 withObjectAtIndex:selectedBrowserIndex];
        }
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    // Determine the preferred browser
    NSString *defaultExternalBrowser = (app.defaultExternalBrowser == nil) ? @"Safari" : app.defaultExternalBrowser;

    // Make the table view highlight the cell for the DefaultExternalBrowser choice
    for (UITableViewCell *cell in self.browsersTableView.visibleCells) {
        if ([cell.textLabel.text isEqualToString:defaultExternalBrowser]) {
            NSIndexPath *indexPath = [self.browsersTableView indexPathForCell:cell];
            [self.browsersTableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:0];
            break;
        }
    }
    
    [self moveOpenInLabelBesideSelectedBrowserCell];
    
    // Round just the top left and bottom left corners of openInLabel
    [self roundCorners:UIRectCornerTopLeft|UIRectCornerBottomLeft ofView:self.openInLabel toRadius:10.0];
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

#pragma mark - Browser Selection Table View

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [installedSupportedBrowserNames count];
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
    UITableViewCell *cell = [self.browsersTableView cellForRowAtIndexPath:indexPath];
    app.defaultExternalBrowser = cell.textLabel.text;
    
    [self moveOpenInLabelBesideSelectedBrowserCell];

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

-(void)moveOpenInLabelBesideSelectedBrowserCell
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
                         float cellHeight = [self.browsersTableView cellForRowAtIndexPath:self.browsersTableView.indexPathForSelectedRow].frame.size.height;
                         
                         // Set label frame shifting it into the same vertical position as the selected cell
                         // Also make the label the same height as the cell
                         self.openInLabel.frame = CGRectMake(self.openInLabel.frame.origin.x, cellY, self.openInLabel.frame.size.width, cellHeight);
                     }
					 completion:^(BOOL finished){
                         
                     }];
}

#pragma mark - Debug Switch

- (IBAction)debugSwitchPushed:(id)sender
{
    app.debugMode = self.debugModeSwitch.on;
    [self setDebugModeLabel];
    [app refreshHistory];
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
