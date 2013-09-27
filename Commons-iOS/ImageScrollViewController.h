//
//  ImageScrollViewController.h
//  Commons-iOS
//
//  Created by Felix Mo on 2013-02-03.


#import <UIKit/UIKit.h>

@interface ImageScrollViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *imageScrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic) float detailsScrollNormal;

-(void)clearOverlay;

@end
