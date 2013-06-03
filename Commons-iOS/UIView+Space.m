//
//  UIView+Space.m
//  Commons-iOS
//
//  Created by MONTE HURD on 5/25/13.

#import "UIView+Space.h"

@implementation UIView (Space)

// Moves self below view. Leaves view in place
-(void)moveBelowView:(UIView *)view spacing:(float)space
{
	self.center = CGPointMake(self.center.x, view.frame.origin.y + view.frame.size.height + space + (self.frame.size.height / 2.0));
}

// Assuming self is to the left of view, reposition *both* view so they have space between them
-(void)moveBesideView:(UIView *)view spacing:(float)space
{
	float presentDistance = view.center.x - self.center.x;
	float desiredDistance = ((view.frame.size.width + self.frame.size.width) / 2.0f) + space;
	float offset = (desiredDistance - presentDistance) / 2.0f;
	self.center = CGPointMake(self.center.x - offset, self.center.y);
	view.center = CGPointMake(view.center.x + offset, view.center.y);
}

@end
