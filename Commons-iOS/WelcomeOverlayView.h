//
//  WelcomeOverlayView.h
//  Commons-iOS
//
//  Created by Monte Hurd on 5/1/13.

#import <UIKit/UIKit.h>

typedef enum {
	WELCOME_MESSAGE_NONE = 0,
	WELCOME_MESSAGE_WELCOME = 1,
	WELCOME_MESSAGE_CHOOSE_OR_TAKE = 2,
    WELCOME_MESSAGE_CHECKING = 3
} WelcomeMessage;

@interface WelcomeOverlayView : UIView

@property (weak, nonatomic) IBOutlet UIButton *addMediaButton;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *choosePhotoButton;

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;

@property(nonatomic) UIInterfaceOrientation interfaceOrientation;

-(void) showMessage:(WelcomeMessage) msg;

-(void) animateLines;
-(void) clearLines;

@end