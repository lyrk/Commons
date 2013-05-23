//
//  MockPageBackgroundView.h
//  Commons-iOS
//
//  Created by Monte Hurd on 5/20/13.

#import <UIKit/UIKit.h>

@class CAShapeLayer;
@interface MockPageBackgroundView : UIView

-(void)drawLinesWithAnimation:(BOOL)animation;
-(void)reset;

@property (nonatomic) CAShapeLayer *lineOne;
@property (nonatomic) CAShapeLayer *lineTwo;
@property (nonatomic) CAShapeLayer *lineThree;
@property (nonatomic) CAShapeLayer *lineFour;
@property (nonatomic) CAShapeLayer *lineFive;

@end
