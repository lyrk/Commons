//
//  MockPageBackgroundView.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/20/13.

#import "MockPageBackgroundView.h"
#import <QuartzCore/QuartzCore.h>
#import "CALerpLine.h"

@implementation MockPageBackgroundView
{
    CALerpLine *lerpLine;
    UIColor *backgroundColorFromIB;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        lerpLine = [[CALerpLine alloc] init];
        self.lineOne = [CAShapeLayer layer];
        self.lineTwo = [CAShapeLayer layer];
        self.lineThree = [CAShapeLayer layer];
        self.lineFour = [CAShapeLayer layer];
        self.lineFive = [CAShapeLayer layer];

        // Prepare the view for the sawtooth bottom to be drawn
        // Respect the color choice from Interface Builder so color may be tweaked w/o code changes
        backgroundColorFromIB = self.backgroundColor;
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
    }
    return self;
}

-(void)reset
{
    [self.lineOne removeFromSuperlayer];
    [self.lineTwo removeFromSuperlayer];
    [self.lineThree removeFromSuperlayer];
    [self.lineFour removeFromSuperlayer];
    [self.lineFive removeFromSuperlayer];
}

-(void)drawLinesWithAnimation:(BOOL)animation
{
    [self reset];
    
    // Block for drawing lines - nice place for common settings
    void(^drawLerpLine)(CAShapeLayer *, CGPoint, CGPoint, CFTimeInterval, float, float) = ^(CAShapeLayer *pathLayer, CGPoint startPoint, CGPoint endPoint, CFTimeInterval duration, float from, float to){
        lerpLine.view = self;
        lerpLine.pathLayer = pathLayer;
        lerpLine.startPoint = startPoint;
        lerpLine.endPoint = endPoint;
        lerpLine.startOffset = 0.0f;
        lerpLine.endOffset = 0.0f;
        lerpLine.duration = duration;
        lerpLine.from = from;
        lerpLine.to = to;
        lerpLine.fillMode = kCAFillModeForwards;
        lerpLine.removedOnCompletion = NO;
        lerpLine.delay = 0.30f;
        lerpLine.lineWidth = 3.0f;
        [lerpLine drawLine];
    };
    
    float duration = (animation) ? 0.17f : 0.0f;
    float to = (animation) ? 0.49f : 1.0f;
    float from = (animation) ? 1.0f : 0.0f;
    
    drawLerpLine(self.lineOne, CGPointMake(61.0f, 30.0f), CGPointMake(99.0f, 30.0f), 0.0f, 0.0f, 1.0f);
    drawLerpLine(self.lineTwo, CGPointMake(61.0f, 53.0f), CGPointMake(216.0f, 53.0f), duration, from, to);
    drawLerpLine(self.lineThree, CGPointMake(61.0f, 74.0f), CGPointMake(216.0f, 74.0f), duration, from, to);
    
    drawLerpLine(self.lineFour, CGPointMake(61.0f, 94.0f), CGPointMake(216.0f, 94.0f), 0.0f, 0.0f, 1.0f);
    drawLerpLine(self.lineFive, CGPointMake(61.0f, 114.0f), CGPointMake(216.0f, 114.0f), 0.0f, 0.0f, 1.0f);
}

- (void)drawRect:(CGRect)rect
{
    [self drawSawtoothBottomBorderInRect:rect];
}

- (void)drawSawtoothBottomBorderInRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(context, kCGBlendModeClear);
    [backgroundColorFromIB setFill];
    UIRectFill(rect);
    int teeth = 26;
    int slices = (teeth * 2) + 1;
    float marginOffset = (self.bounds.size.width / slices) * 1.5;
    CGContextMoveToPoint(context, 0.0f, self.bounds.size.height);
    CGContextAddLineToPoint(context, 0.0f, self.bounds.size.height);
    float sliceWidth = self.bounds.size.width / slices;
    for (NSUInteger k = 0; k < slices - 2; k++)
    {
        float x = (sliceWidth * k) + marginOffset;
        float y = (k % 2) ? self.bounds.size.height - 3.0f : self.bounds.size.height - 8.0f;
        CGContextAddLineToPoint(context, x, y);
    }
    CGContextAddLineToPoint(context, self.bounds.size.width, self.bounds.size.height);
    CGContextClosePath(context);
    CGContextFillPath(context);
}

@end
