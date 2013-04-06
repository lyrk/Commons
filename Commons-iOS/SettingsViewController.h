//
//  SettingsViewController.h
//  Commons-iOS
//
//  Created by MONTE HURD on 4/5/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *debugModeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *debugModeSwitch;
@property (weak, nonatomic) IBOutlet UILabel *uploadTargetLabel;

- (IBAction)debugSwitchPushed:(id)sender;

@end
