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

- (IBAction)yesButtonPushed:(id)sender;

@end
