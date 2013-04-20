//
//  SettingsViewController.h
//  Commons-iOS
//
//  Created by MONTE HURD on 4/5/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController <UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UILabel *debugModeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *debugModeSwitch;
@property (weak, nonatomic) IBOutlet UILabel *uploadTargetLabel;
@property (weak, nonatomic) IBOutlet UIButton *openInButton;

- (IBAction)debugSwitchPushed:(id)sender;
- (IBAction)chooseBrowserButtonPushed:(id)sender;

@end
