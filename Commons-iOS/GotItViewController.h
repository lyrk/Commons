//
//  GotItViewController.h
//  Commons-iOS
//
//  Created by Monte Hurd on 5/21/13.

#import <UIKit/UIKit.h>

@interface GotItViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *mockPageContainerView;
@property (strong, nonatomic) IBOutlet UIView *mockBadPhotoContainerView;
@property (strong, nonatomic) IBOutlet UIButton *yesButton;
@property (strong, nonatomic) IBOutlet UILabel *gotItLabel;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *verticalSpaceBetweenLabels;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *verticalSpaceBetweenHalves;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *gotItLabelWidth;

- (IBAction)yesButtonPushed:(id)sender;

@end
