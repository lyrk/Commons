//
//  SettingsViewController.m
//  Commons-iOS
//
//  Created by MONTE HURD on 4/5/13.

#import "SettingsViewController.h"
#import "CommonsApp.h"
#import "mwapi/MWApi.h"
#import "MWI18N/MWMessage.h"
#import "GradientButton.h"

@interface SettingsViewController (){
    NSMutableArray *browserSchemes;
}

-(NSString *)getSelectedBrowserName;
-(void)updateOpenInButtonTitle;
-(void)showBrowserSelectionActionSheet;

@end

@implementation SettingsViewController

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        browserSchemes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	CommonsApp *app = CommonsApp.singleton;

	self.debugModeLabel.text = [MWMessage forKey:@"settings-debug-label"].text;
    self.navigationItem.title = [MWMessage forKey:@"settings-title"].text;
    self.openInLabel.text = [MWMessage forKey:@"settings-open-links-label"].text;
    
    self.openInButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.openInLabel.adjustsFontSizeToFitWidth = YES;
    
    self.debugModeSwitch.on = app.debugMode;
    [self setDebugModeLabel];
	
    [self updateOpenInButtonTitle];
    
    [self.openInButton useBlackActionSheetStyle];
}

- (IBAction)debugSwitchPushed:(id)sender {
    CommonsApp *app = CommonsApp.singleton;
    app.debugMode = self.debugModeSwitch.on;
    [self setDebugModeLabel];
    [app refreshHistory];
}

-(void)updateOpenInButtonTitle
{
    // Use just the browser name for the button text
    NSString *buttonText = [self getSelectedBrowserName];
    
    // Animate the button just a bit to draw attention to the updated browser choice
    // Makes it get a bit bigger, then it shrinks back down
    [UIView animateWithDuration:0.20
						  delay:0.0
						options:UIViewAnimationOptionTransitionNone
					 animations:^{
                         self.openInButton.transform = CGAffineTransformMakeScale(1.15, 1.15);
					 }
					 completion:^(BOOL finished){
                         self.openInButton.transform = CGAffineTransformIdentity;
                         [self.openInButton setTitle:buttonText forState:UIControlStateNormal];
					 }];
}

-(NSString *)getSelectedBrowserName
{    
    NSString *defaultExternalBrowser = [[NSUserDefaults standardUserDefaults] objectForKey:@"DefaultExternalBrowser"];
    return (defaultExternalBrowser == nil) ? @"Safari" : defaultExternalBrowser;
}

- (IBAction)chooseBrowserButtonPushed:(id)sender
{
    [self showBrowserSelectionActionSheet];
}

-(void)showBrowserSelectionActionSheet
{   // Build and show an action sheet with a button for each browser found on the device
    
    // This is the text that appears on the top of the aciton sheet
    NSString *actionSheetPrompt = [NSString stringWithFormat:@"%@\n%@",
                                       [MWMessage forKey:@"settings-browsers-detected"].text,
                                       [MWMessage forKey:@"settings-open-links-label"].text
                                   ];
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:actionSheetPrompt
                                                       delegate:self
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:nil];
    
    // Block for adding browser buttons to the action sheet
    void(^addBrowserButton)() = ^(NSString *browserName, NSString *scheme){
        if ([[UIApplication sharedApplication] canOpenURL: [NSURL URLWithString:[NSString stringWithFormat:@"%@://", scheme]]]) {
            NSInteger index = [sheet addButtonWithTitle:browserName];
            [browserSchemes insertObject:scheme atIndex:index];
        }
    };

    // Browsers to check for
    addBrowserButton(@"Chrome", @"googlechrome");
    //addBrowserButton(@"Dolphin", @"dolphin"); //dolphin doesn't support https scheme from external device???
    addBrowserButton(@"Opera", @"ohttp");
    addBrowserButton(@"Safari", @"http");
    
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        // Just tap outside to dismiss on iPad...
        int cancelIndex = [sheet addButtonWithTitle:[MWMessage forKey:@"web-cancel"].text];
        sheet.cancelButtonIndex = cancelIndex;
    }
    
    // Show the action sheet
    [sheet showInView:self.view];
}

#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.cancelButtonIndex == buttonIndex) return;

    // Save the browser selection w/NSUserDefaults so it can be easily checked by openURLWithDefaultBrowser
    [[NSUserDefaults standardUserDefaults] setObject:[actionSheet buttonTitleAtIndex:buttonIndex] forKey:@"DefaultExternalBrowser"];

    // Also save the scheme so openURLWithDefaultBrowser can verify that the selected browser is still on the device
    // because the user may have deleted it since making their selection. When this happens openURLWithDefaultBrowser
    // will switch back to Safari
    [[NSUserDefaults standardUserDefaults] setObject:[browserSchemes objectAtIndex:buttonIndex] forKey:@"DefaultExternalBrowserScheme"];

    [[NSUserDefaults standardUserDefaults] synchronize];

    [self updateOpenInButtonTitle];
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

- (void)viewDidUnload {
    [self setDebugModeSwitch:nil];
    [self setDebugModeLabel:nil];
	[self setUploadTargetLabel:nil];

    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
