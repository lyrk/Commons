//
//  AboutViewController.h
//  Commons-iOS
//
//  Created by Monte Hurd on 4/12/13.

#import <UIKit/UIKit.h>
@class GradientButton;

@interface AboutViewController : UIViewController

@property (weak, nonatomic) IBOutlet GradientButton *commonsButton;
@property (weak, nonatomic) IBOutlet GradientButton *bugsButton;
@property (weak, nonatomic) IBOutlet GradientButton *privacyButton;
@property (weak, nonatomic) IBOutlet GradientButton *sourceButton;

@property (weak, nonatomic) IBOutlet UIButton *thisAppSourceButton;
@property (weak, nonatomic) IBOutlet UIButton *thisAppLicenseButton;
@property (weak, nonatomic) IBOutlet UIButton *thisAppContributorsButton ;

@property (weak, nonatomic) IBOutlet UIButton *gradientButtonSourceButton;
@property (weak, nonatomic) IBOutlet UIButton *gradientButtonLicenseButton;

@property (weak, nonatomic) IBOutlet UILabel *thisAppLabel;
@property (weak, nonatomic) IBOutlet UILabel *gradientButtonsLabel;

@property (weak, nonatomic) IBOutlet UILabel *appNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *appVersionLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UIView *aboutContainer;
@property (weak, nonatomic) IBOutlet UIView *sourceDetailsContainer;

-(IBAction)sourceButtonTap:(id)sender;
-(IBAction)openURLinExternalBrowser:(id)sender;

@end
