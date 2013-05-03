//
//  SettingsViewController.h
//  Commons-iOS
//
//  Created by MONTE HURD on 4/5/13.

#import <UIKit/UIKit.h>

@class GradientButton;
@interface SettingsViewController : UIViewController <UIActionSheetDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *debugModeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *debugModeSwitch;
@property (weak, nonatomic) IBOutlet UIView *debugInfoContainer;
@property (weak, nonatomic) IBOutlet UILabel *uploadTargetLabel;
@property (weak, nonatomic) IBOutlet UILabel *openInLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *settingsContainer;
@property (weak, nonatomic) IBOutlet UITableView *browsersTableView;
@property (weak, nonatomic) IBOutlet UISwitch *trackingSwitch;
@property (weak, nonatomic) IBOutlet UILabel *trackingLabel;
@property (weak, nonatomic) IBOutlet UILabel *trackingDetailsLabel;

- (IBAction)debugSwitchPushed:(id)sender;

@end
