
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

- (void)animateProgress:(float)progress
{
    // Smooth the download progress bar advance by drawing a number of intermediate states between its current progressNormal and the value passed to the method via the "progress" parameter
    float lastProgress = self.progressNormal;
    if ((progress > 0) && (progress > lastProgress)) {
        float delay = 0.010;
        int frames = 15;
        float diffProgress = progress - lastProgress;
        for (int i = 0; i < frames + 1; i++) {
            float intermediateProgress = lastProgress + (diffProgress * (i * (1.0 / frames)));
            dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * (delay * i));
            dispatch_after(delayTime, dispatch_get_main_queue(), ^(void){
                self.progressNormal = (intermediateProgress == 1.0) ? 0.0 : intermediateProgress;
                [self setNeedsDisplay];
            });
        }
    }else{
        self.progressNormal = 0;
        [self setNeedsDisplay];
    }
    //NSLog(@"Image Download Progress = %f", progress);
}

@end
