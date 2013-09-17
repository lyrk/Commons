//
//  SettingsViewController.h
//  Commons-iOS
//
//  Created by MONTE HURD on 4/5/13.

#import <UIKit/UIKit.h>

@class UIButtonDynamicHeight;

@interface SettingsViewController : UIViewController <UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UILabel *debugModeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *debugModeSwitch;
@property (weak, nonatomic) IBOutlet UIView *debugInfoContainer;
@property (weak, nonatomic) IBOutlet UILabel *uploadTargetLabel;
@property (weak, nonatomic) IBOutlet UILabel *openInLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *settingsContainer;
@property (weak, nonatomic) IBOutlet UILabel *trackingLabel;
@property (weak, nonatomic) IBOutlet UILabel *trackingDetailsLabel;
@property (weak, nonatomic) IBOutlet UIView *trackingInfoContainer;

@property (weak, nonatomic) IBOutlet UILabel *appNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *appVersionLabel;

@property (weak, nonatomic) IBOutlet UIButtonDynamicHeight *commonsButton;
@property (weak, nonatomic) IBOutlet UIButtonDynamicHeight *bugsButton;
@property (weak, nonatomic) IBOutlet UIButtonDynamicHeight *privacyButton;
@property (weak, nonatomic) IBOutlet UILabel *sourceLabel;

@property (weak, nonatomic) IBOutlet UIButtonDynamicHeight *thisAppSourceButton;
@property (weak, nonatomic) IBOutlet UIButtonDynamicHeight *thisAppLicenseButton;
@property (weak, nonatomic) IBOutlet UIButtonDynamicHeight *thisAppContributorsButton ;

@property (weak, nonatomic) IBOutlet UIButtonDynamicHeight *gradientButtonSourceButton;
@property (weak, nonatomic) IBOutlet UIButtonDynamicHeight *gradientButtonLicenseButton;

@property (weak, nonatomic) IBOutlet UILabel *thisAppLabel;
@property (weak, nonatomic) IBOutlet UILabel *gradientButtonsLabel;

@property (weak, nonatomic) IBOutlet UILabel *externalLinksLabel;
@property (weak, nonatomic) IBOutlet UIView *externalBrowserContainer;
@property (weak, nonatomic) IBOutlet UIView *externalLinksContainer;

@property (weak, nonatomic) IBOutlet UIView *sourceDetailsContainer;

@property (strong, nonatomic) IBOutlet UIView *mockPageContainerView;

@property (weak, nonatomic) IBOutlet UIButtonDynamicHeight *sendUsageReportsButton;
@property (weak, nonatomic) IBOutlet UIButtonDynamicHeight *dontSendUsageReportsButton;

-(IBAction)openURLinExternalBrowser:(id)sender;
-(IBAction)debugSwitchPushed:(id)sender;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *spaceAboveMockPageConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *spaceBetweenDebugAndBrowserContainersConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *spaceBetweenBrowserAndLinksContainersConstraint;

@end
