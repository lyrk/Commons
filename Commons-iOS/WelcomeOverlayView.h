//
//  WelcomeOverlayView.h
//  Commons-iOS
//
//  Created by Monte Hurd on 5/1/13.

#import <UIKit/UIKit.h>

typedef enum {
	NONE = 0,
	WELCOME = 1,
	CHOOSE_OR_TAKE = 2
} WelcomeMessage;

@interface WelcomeOverlayView : UIView

@property (weak, nonatomic) IBOutlet UIButton *addMediaButton;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *choosePhotoButton;

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;

@property(nonatomic) UIInterfaceOrientation interfaceOrientation;

-(void) showMessage:(WelcomeMessage) msg;

@end