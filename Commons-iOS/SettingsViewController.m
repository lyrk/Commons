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

	self.debugModeLabel.text = [MWMessage forKey:@"settings-debug-label"].text;
    self.navigationItem.title = [MWMessage forKey:@"settings-title"].text;

    self.debugModeSwitch.on = app.debugMode;
    [self setDebugModeLabel];
	
}

- (IBAction)debugSwitchPushed:(id)sender {
    CommonsApp *app = CommonsApp.singleton;
    app.debugMode = self.debugModeSwitch.on;
    [self setDebugModeLabel];
    [app refreshHistory];
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
