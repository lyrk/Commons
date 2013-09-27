//
//  UILabel+ResizeWithAttributes.h
//  Commons-iOS
//
//  Created by MONTE HURD on 5/25/13.

#import <UIKit/UIKit.h>

@interface UILabel (ResizeWithAttributes)

-(void)resizeWithAttributes:(NSDictionary *)attributes preferredMaxLayoutWidth:(CGFloat)width;

@end
