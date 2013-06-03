//
//  CALerpLine.h
//  Commons-iOS
//
//  Created by Monte Hurd on 5/22/13.

#import <Foundation/Foundation.h>

@class CAShapeLayer;
@interface CALerpLine : NSObject

@property (strong, nonatomic) UIView *view;
@property (strong, nonatomic) CAShapeLayer *pathLayer;
@property (nonatomic) CGPoint startPoint;
@property (nonatomic) CGPoint endPoint;
@property (nonatomic) float startOffset;
@property (nonatomic) float endOffset;
@property (nonatomic) CFTimeInterval duration;
@property (nonatomic) float from;
@property (nonatomic) float to;

@property (strong, nonatomic) NSString *fillMode;
@property (nonatomic) BOOL removedOnCompletion;
@property (nonatomic) CFTimeInterval delay;

@property (strong, nonatomic) UIColor *strokeColor;
@property (nonatomic) CGFloat lineWidth;
@property (strong, nonatomic) NSArray *lineDashPattern;

-(void)drawLine;

@end
