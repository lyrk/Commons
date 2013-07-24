//
//  PictureOfDayCycler.m
//  Commons-iOS
//
//  Created by Monte Hurd on 6/12/13.

#import "PictureOfDayCycler.h"
#import "CommonsApp.h"

@interface PictureOfDayCycler (){
    NSTimer *timer_;
    uint currentIndex_;
}
@end

@implementation PictureOfDayCycler

- (id)init
{
    self = [super init];
    if (self) {
        self.displayInterval = 3.0f;
        self.transitionDuration = 1.0f;
        currentIndex_ = 0;
        timer_ = nil;
    }
    return self;
}

-(BOOL)isCycling
{
    return (!(timer_ == nil));
}

-(void)start
{
    // Added initial call to "first" on a shorter timer because the initial image isn't
    // fading in from a previous image and thus *looks* like it's taking longer even
    // thought it isn't. Since NSTimer can't have its timerInterval changed once it's
    // been created the timer created in this method only fires once ("repeats:NO").
    // Then the timer kicked off by "first" *does* repeat, but with the full
    // transitionInterval
    if (timer_ == nil){
        timer_ = [NSTimer scheduledTimerWithTimeInterval:(self.displayInterval - self.transitionDuration) target:self
                                                     selector:@selector(first)
                                                     userInfo:nil
                                                      repeats:NO];
    }
}

-(void)stop
{
    if (timer_ != nil){
        [timer_ invalidate];
        timer_ = nil;
    }
}

-(void)first
{
    [self next];
    [self stop];
    
    if (timer_ == nil){
        timer_ = [NSTimer scheduledTimerWithTimeInterval:(self.displayInterval) target:self
                                                     selector:@selector(next)
                                                     userInfo:nil
                                                      repeats:YES];
    }
}

-(void)next
{
    if (self.dateStrings.count < 2) return;
    
    if (currentIndex_ > (self.dateStrings.count - 1)) currentIndex_ = self.dateStrings.count - 1;
    
    NSString *dateString = self.dateStrings[currentIndex_];
    
    self.cycle(dateString);
    
    currentIndex_ = (currentIndex_ == (self.dateStrings.count - 1)) ? 0 : currentIndex_ + 1;
}

@end
