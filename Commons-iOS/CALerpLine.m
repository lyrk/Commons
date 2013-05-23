//
//  CALerpLine.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/22/13.

#import "CALerpLine.h"
#import <QuartzCore/QuartzCore.h>

@implementation CALerpLine

- (id)init
{
    self = [super init];
    if (self) {
        self.fillMode = kCAFillModeRemoved;
        self.removedOnCompletion = YES;
        self.delay = 0.0f;
        
        self.strokeColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        self.lineWidth = 1.0f;
        self.lineDashPattern = nil;
        self.startOffset = 0.0f;
        self.endOffset = 0.0f;
        self.from = 0.0f;
        self.to = 1.0f;
    }
    return self;
}

-(void)drawLine
{
    // Used to make smaller line segments
    float(^lerp)(float, float, float) = ^(float v0, float v1, float t)
    {
        return v0 + (v1 - v0) * t;
    };
    
    CGPoint lerpedStart = CGPointMake(lerp(self.endPoint.x, self.startPoint.x, self.endOffset), lerp(self.endPoint.y, self.startPoint.y, self.endOffset));
    CGPoint lerpedEnd = CGPointMake(lerp(self.startPoint.x, self.endPoint.x, self.startOffset), lerp(self.startPoint.y, self.endPoint.y, self.startOffset));
    
    // Determine if the line about to be drawn is already onscreen
    if (self.pathLayer.path != nil) {
        // Check for both points
        if(
           (CGPathContainsPoint(self.pathLayer.path, nil, lerpedStart, false))
           &&
           (CGPathContainsPoint(self.pathLayer.path, nil, lerpedEnd, false))
           ){
            // Check layer presense (determines whether the pathLayer actually on-screen)
            if(NSNotFound != [self.view.layer.sublayers indexOfObject:self.pathLayer]) {
                // The line already exists, so don't redraw
                return;
            }
        }
    }
    
    // Safe to animate drawing of the line
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:lerpedEnd];
    [path addLineToPoint:lerpedStart];
    
    self.pathLayer.frame = self.view.bounds;
    self.pathLayer.path = path.CGPath;
    self.pathLayer.strokeColor = [self.strokeColor CGColor];
    self.pathLayer.fillColor = nil;
    self.pathLayer.lineJoin = kCALineJoinBevel;
    self.pathLayer.lineWidth = self.lineWidth;
    self.pathLayer.lineDashPattern = self.lineDashPattern;
    
    [self.view.layer addSublayer:self.pathLayer];
    
    // Allow the line to be drawn even if not being animated
    if (self.duration == 0.0f) return;
    
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    pathAnimation.duration = self.duration;//0.35;
    pathAnimation.fromValue = @(self.from);
    pathAnimation.toValue = @(self.to);

    pathAnimation.fillMode = self.fillMode;
    pathAnimation.removedOnCompletion = self.removedOnCompletion;
    [pathAnimation setBeginTime:CACurrentMediaTime() + self.delay];

    [self.pathLayer removeAllAnimations];
    
    [self.pathLayer addAnimation:pathAnimation forKey:@"strokeEnd"];
}

@end
