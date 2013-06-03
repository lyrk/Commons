//
//  MockBadPhotoViewController.h
//  Commons-iOS
//
//  Created by Monte Hurd on 5/20/13.

#import <UIKit/UIKit.h>

@interface MockBadPhotoViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIImageView *mockBadPhoto;
@property (strong, nonatomic) IBOutlet UIImageView *mockBadPhotoBackground;
@property (strong, nonatomic) IBOutlet UIView *blendBacking;
@property (strong, nonatomic) IBOutlet UIView *blendMiddle;
@property (nonatomic) float animationDelay;

@end
