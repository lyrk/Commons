//
//  SettingsViewController.m
//  Commons-iOS
//
//  Created by MONTE HURD on 4/5/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "SettingsViewController.h"
#import "CommonsApp.h"
#import "mwapi/MWApi.h"
#import "MWI18N/MWMessage.h"
#import "BrowserHelper.h"

@interface SettingsViewController ()

-(NSString *)getSelectedBrowserName;
-(void)updateOpenInButtonTitle;

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

	self.debugModeLabel.text = [MWMessage forKey:@"settings-debug-label"].text;
    self.navigationItem.title = [MWMessage forKey:@"settings-title"].text;

    self.debugModeSwitch.on = app.debugMode;
    [self setDebugModeLabel];
	
    [self updateOpenInButtonTitle];
}

- (IBAction)debugSwitchPushed:(id)sender {
    CommonsApp *app = CommonsApp.singleton;
    app.debugMode = self.debugModeSwitch.on;
    [self setDebugModeLabel];
    [app refreshHistory];
}

-(void)updateOpenInButtonTitle
{
    
    
    NSString *buttonText = [MWMessage forKey:@"web-open-in" param:[self getSelectedBrowserName]].text;

    [self.openInButton setTitle:buttonText forState:UIControlStateNormal];

}

-(NSString *)getSelectedBrowserName
{    
    NSString *defaultExternalBrowser = [[NSUserDefaults standardUserDefaults] objectForKey:@"DefaultExternalBrowser"];
    return (defaultExternalBrowser == nil) ? @"Safari" : defaultExternalBrowser;
}

- (IBAction)chooseBrowserButtonPushed:(id)sender {

    
/*
add l10n for "Open Links With"
what to do if only safari present?
store setting in nsuserdefaults

write openURLWithDefaultBrowser: method which reads the user default and opens the link
use it everywhere!
*/
 
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"The following browsers were detected.\nOpen external links with:"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:nil];

    
    if ([[UIApplication sharedApplication] canOpenURL: [NSURL URLWithString:@"googlechrome://"]]) {
        int index = [sheet addButtonWithTitle:@"Chrome"];
    }
    
    if ([[UIApplication sharedApplication] canOpenURL: [NSURL URLWithString:@"dolphin://"]]) {
        int index = [sheet addButtonWithTitle:@"Dolphin"];
    }
    
    if ([[UIApplication sharedApplication] canOpenURL: [NSURL URLWithString:@"ohttp://"]]) {
        int index = [sheet addButtonWithTitle:@"Opera"];
    }
    
    int index = [sheet addButtonWithTitle:@"Safari"];

    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        // Just tap outside to dismiss on iPad...
        int cancelIndex = [sheet addButtonWithTitle:[MWMessage forKey:@"web-cancel"].text];
        sheet.cancelButtonIndex = cancelIndex;
    }

    [sheet showInView:self.view];

    
    
    
    
    
    
    
    
    
    
    
    return;
//    if (helper == nil) {
        BrowserHelper *helper = [[BrowserHelper alloc] initWithURL:[NSURL URLWithString:@"google.com"]];
//        self.helper = helper;
//        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//            [helper showFromBarButtonItem:self.actionButton onCompletion:^() {
//                self.helper = nil;
//            }];
//        } else {
            [helper showInView:self.view onCompletion:^() {
//                self.helper = nil;
            }];
//        }
//    }
}

#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.cancelButtonIndex == buttonIndex) {
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[actionSheet buttonTitleAtIndex:buttonIndex] forKey:@"DefaultExternalBrowser"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self updateOpenInButtonTitle];

    NSLog(@"%@", [actionSheet buttonTitleAtIndex:buttonIndex]);

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
