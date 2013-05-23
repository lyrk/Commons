//
//  GettingStartedViewController.h
//  Commons-iOS
//
//  Created by Monte Hurd on 5/22/13.

#import <UIKit/UIKit.h>

@interface GettingStartedViewController : UIViewController <UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;

- (IBAction)changePage:(id)sender;

@end
