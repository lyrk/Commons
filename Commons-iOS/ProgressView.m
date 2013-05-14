
#import "ProgressView.h"

@implementation ProgressView

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
    {
        _progressNormal = 0.0;
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(context, kCGBlendModeHardLight);    
    UIColor *overlayColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.2];
    CGContextSetFillColorWithColor(context, overlayColor.CGColor);
    
    CGRect overlayBounds = CGRectMake(
                                      self.bounds.origin.x,
                                      self.bounds.origin.y,
                                      self.bounds.size.width * _progressNormal,
                                      self.bounds.size.height
                                      );
    CGContextFillRect(context, overlayBounds);
	CGContextStrokePath(context);
}

@end
