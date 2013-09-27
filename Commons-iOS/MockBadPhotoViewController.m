//
//  MockBadPhotoViewController.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/20/13.

#import "MockBadPhotoViewController.h"
#import "CALerpLine.h"
#import <QuartzCore/QuartzCore.h>
#import "GettingStartedConstants.h"

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
    
    [self.mockBadPhoto.layer removeAllAnimations];
    [self.mockBadPhotoBackground.layer removeAllAnimations];
    [self.blendBacking.layer removeAllAnimations];
    [self.blendMiddle.layer removeAllAnimations];
}

-(void)viewWillLayoutSubviews
{
    self.blendBacking.backgroundColor = GETTING_STARTED_BG_COLOR;
    self.blendMiddle.backgroundColor = [UIColor whiteColor];    
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        lerpLine_ = [[CALerpLine alloc] init];
        strikeForegroundLine_ = [CAShapeLayer layer];
        strikeBackgroundLine_ = [CAShapeLayer layer];
		self.animationDelay = 0.0f;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor clearColor];

    self.mockBadPhotoBackground.image = self.mockBadPhoto.image;
    self.blendMiddle.alpha = GETTING_STARTED_MOCK_BAD_PHOTO_ALPHA_FRONT;
    
    [self.view bringSubviewToFront:self.blendBacking];
    [self.view bringSubviewToFront:self.blendMiddle];

    self.blendBacking.hidden = NO;
    self.blendMiddle.hidden = NO;
    
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
        lerpLine_.delay = 0.55;
        lerpLine_.fillMode = kCAFillModeBackwards; // Needed for delayed draw
        lerpLine_.removedOnCompletion = NO;
        [lerpLine_ drawLine];
    };
    drawLerpLine(strikeBackgroundLine_, GETTING_STARTED_BG_COLOR, 13.0f);
    drawLerpLine(strikeForegroundLine_, [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0], 4.0f);
    
    CABasicAnimation *(^animatePathToValue)(NSString *, NSValue *) = ^(NSString *path, NSValue *toValue){
        CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:path];
        a.fillMode = kCAFillModeForwards;
        a.autoreverses = NO;
        a.duration = 0.33f;
        a.removedOnCompletion = NO;
        [a setBeginTime:CACurrentMediaTime()];
        a.toValue = toValue;
        return a;
    };
    
    [self.mockBadPhotoBackground.layer addAnimation:animatePathToValue(@"opacity", @GETTING_STARTED_MOCK_BAD_PHOTO_ALPHA_BACK) forKey:nil];
    
    CATransform3D xf = CATransform3DConcat(
                                           CATransform3DMakeRotation(DEGREES_TO_RADIANS(-10.0f), 0, 0, 1),
                                           CATransform3DMakeTranslation(-10.0f, -23.0f, 0)
                                           );
    [self.mockBadPhotoBackground.layer addAnimation:animatePathToValue(@"transform", [NSValue valueWithCATransform3D:xf]) forKey:nil];
    
    xf = CATransform3DMakeRotation(DEGREES_TO_RADIANS(7.0f), 0, 0, 1);
    [self.mockBadPhoto.layer addAnimation:animatePathToValue(@"transform", [NSValue valueWithCATransform3D:xf]) forKey:nil];
    [self.blendBacking.layer addAnimation:animatePathToValue(@"transform", [NSValue valueWithCATransform3D:xf]) forKey:nil];
    [self.blendMiddle.layer addAnimation:animatePathToValue(@"transform", [NSValue valueWithCATransform3D:xf]) forKey:nil];
}

-(void)viewDidAppear:(BOOL)animated
{
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, self.animationDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
		[self animateBadPhoto];
	});
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
