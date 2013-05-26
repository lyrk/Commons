//
//  UIView+VerticalSpace.m
//  Commons-iOS
//
//  Created by MONTE HURD on 5/25/13.

#import "UIView+VerticalSpace.h"

@implementation UIView (VerticalSpace)

-(void)moveBelowView:(UIView *)view spacing:(float)space
{
	self.center = CGPointMake(self.center.x, view.frame.origin.y + view.frame.size.height + space + (self.frame.size.height / 2.0));
}

@end
