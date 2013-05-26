//
//  MockPageViewController.h
//  Commons-iOS
//
//  Created by Monte Hurd on 5/20/13.

#import <UIKit/UIKit.h>

@interface MockPageViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIImageView *mockPagePhoto;
@property (strong, nonatomic) IBOutlet UIImageView *mockPageLogo;
@property (nonatomic) float animationDelay;
@property (nonatomic) BOOL animationDelayOnce;

@end
