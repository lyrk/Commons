//
//  PictureOfDayCycler.m
//  Commons-iOS
//
//  Created by Monte Hurd on 6/12/13.

#import "PictureOfDayCycler.h"
#import "CommonsApp.h"

@interface PictureOfDayCycler (){
    NSTimer *timer_;
}
@end

@implementation PictureOfDayCycler

- (id)init
{
    self = [super init];
    if (self) {
        self.displayInterval = 3.0f;
        self.transitionDuration = 1.0f;
        self.currentDateStringIndex = 0;
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
    _currentDateString = self.dateStrings[self.currentDateStringIndex];

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
    
    if (self.currentDateStringIndex > (self.dateStrings.count - 1)) self.currentDateStringIndex = self.dateStrings.count - 1;
    
    _currentDateString = self.dateStrings[self.currentDateStringIndex];
    
    self.cycle(self.currentDateString);
    
    self.currentDateStringIndex = (self.currentDateStringIndex == (self.dateStrings.count - 1)) ? 0 : self.currentDateStringIndex + 1;
}

@end
