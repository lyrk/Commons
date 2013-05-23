//
//  MockBadPhotoViewController.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/20/13.

#import "MockBadPhotoViewController.h"
#import "CALerpLine.h"
#import <QuartzCore/QuartzCore.h>

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface MockBadPhotoViewController (){
    CALerpLine *lerpLine_;
    CAShapeLayer *strikeForegroundLine_;
    CAShapeLayer *strikeBackgroundLine_;
}
@end

@implementation MockBadPhotoViewController

-(void)viewDidDisappear:(BOOL)animated
{
    [self reset];
}

-(void)reset
{
    [strikeForegroundLine_ removeFromSuperlayer];
    [strikeBackgroundLine_ removeFromSuperlayer];
    self.mockBadPhoto.transform = CGAffineTransformIdentity;
    self.mockBadPhotoBackground.transform = CGAffineTransformIdentity;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        lerpLine_ = [[CALerpLine alloc] init];
        strikeForegroundLine_ = [CAShapeLayer layer];
        strikeBackgroundLine_ = [CAShapeLayer layer];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor clearColor];

    self.mockBadPhotoBackground.image = self.mockBadPhoto.image;
    [self.view bringSubviewToFront:self.mockBadPhoto];
}

-(void)animateBadPhoto
{
    // Block for drawing lines - nice place for common settings
    void(^drawLerpLine)(CAShapeLayer *, UIColor*, CGFloat) = ^(CAShapeLayer *pathLayer, UIColor *color, CGFloat lineWidth){
        lerpLine_.view = self.view;
        lerpLine_.pathLayer = pathLayer;
        lerpLine_.startPoint = CGPointMake(40.0f, -28.0f);
        lerpLine_.endPoint = CGPointMake(210.0f, 140.0f);
        lerpLine_.duration = 0.24f;
        lerpLine_.strokeColor = color;
        lerpLine_.lineWidth = lineWidth;
        lerpLine_.delay = 0.66;
        lerpLine_.fillMode = kCAFillModeBackwards; // Needed for delayed draw
        lerpLine_.removedOnCompletion = NO;
        [lerpLine_ drawLine];
    };
    drawLerpLine(strikeBackgroundLine_, [UIColor colorWithRed:0.17 green:0.38 blue:0.59 alpha:1.0], 13.0f);
    drawLerpLine(strikeForegroundLine_, [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0], 4.0f);
    
    [UIView animateWithDuration:0.33
						  delay:0.11
						options:UIViewAnimationOptionTransitionNone
					 animations:^{
                         CGAffineTransform xf = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-10.0f));
                         self.mockBadPhotoBackground.transform = CGAffineTransformTranslate(xf, -10.0f, -23.0f);
                         self.mockBadPhotoBackground.alpha = 0.2;
                         self.mockBadPhoto.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(7.0f));
					 }
					 completion:^(BOOL finished){
                         
                         return; // Comment for a little extra animation
                         
                         __block CGAffineTransform xf1 = self.mockBadPhoto.transform;
                         __block CGAffineTransform xf2 = self.mockBadPhotoBackground.transform;
                         __block CGAffineTransform xf3 = CGAffineTransformScale(xf1, 1.3, 1.3);
                         __block CGAffineTransform xf4 = CGAffineTransformScale(xf2, 1.3, 1.3);
                         
                         xf3 = CGAffineTransformRotate(xf3, DEGREES_TO_RADIANS(10.0f));
                         xf4 = CGAffineTransformRotate(xf4, DEGREES_TO_RADIANS(-10.0f));
                         
                         [UIView animateWithDuration:0.16
                                               delay:0.0
                                             options:UIViewAnimationTransitionNone
                                          animations:^{
                                              self.mockBadPhoto.transform = xf3;
                                              self.mockBadPhotoBackground.transform = xf4;
                                          }
                                          completion:^(BOOL finished){
                                              [UIView animateWithDuration:0.16 animations:^{
                                                  self.mockBadPhoto.transform = xf1;
                                                  self.mockBadPhotoBackground.transform = xf2;
                                              }];
                                          }];
					 }];
}

-(void)viewDidAppear:(BOOL)animated
{
    [self animateBadPhoto];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
