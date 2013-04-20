//
//  SettingsViewController.h
//  Commons-iOS
//
//  Created by MONTE HURD on 4/5/13.

#import <UIKit/UIKit.h>

@class GradientButton;
@interface SettingsViewController : UIViewController <UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UILabel *debugModeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *debugModeSwitch;
@property (weak, nonatomic) IBOutlet UILabel *uploadTargetLabel;
@property (weak, nonatomic) IBOutlet GradientButton *openInButton;
@property (weak, nonatomic) IBOutlet UILabel *openInLabel;

- (IBAction)debugSwitchPushed:(id)sender;
- (IBAction)chooseBrowserButtonPushed:(id)sender;

@end
