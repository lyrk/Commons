//
//  SpeedGovernor.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/8/13.

#import "SpeedGovernor.h"

#define MAX_ACCUMULATOR_DURATION 15.0

typedef enum {
	CONNECTION_SPEED_VERYLOW = 0,
	CONNECTION_SPEED_LOW = 1,
	CONNECTION_SPEED_NORMAL = 2,
	CONNECTION_SPEED_HIGH = 3,
	CONNECTION_SPEED_VERYHIGH = 4
} ConnectionSpeed;

@interface SpeedGovernor()

- (void)reset;
- (void)updateConnectionSpeed;
- (float)getImageResolutionMultiplierForConnectionSpeed;
- (NSInteger)getMaxConcurrentOperationCountForConnectionSpeed;

@end

@implementation SpeedGovernor{
    uint downloadCount_;
    ConnectionSpeed connectionSpeed_;
    double downloadDurationAccumulator_;
    NSTimeInterval averageDownloadDuration_;
    NSTimeInterval accumulatorStartInterval_;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self reset];
        self.imageResolutionMultiplier = 1;
        self.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (void)reportDownloadDuration:(NSTimeInterval)downloadDuration
{
    // Reset everything every MAX_ACCUMULATOR_DURATION seconds so large changes in connection
    // speeds don't result in throttling lasting too long 
    if (([NSDate timeIntervalSinceReferenceDate] - accumulatorStartInterval_) > MAX_ACCUMULATOR_DURATION) {
        [self reset];
    }

    // Calculate the averageDownloadDuration_ so the updateConnectionSpeed method can decide how
    // fast our present connection seems
    downloadCount_++;
    downloadDurationAccumulator_ += downloadDuration;
    averageDownloadDuration_ = downloadDurationAccumulator_ / downloadCount_;
    
    //NSLog(@"AVERAGE DOWNLOAD DURATION = %f", averageDownloadDuration_);
    [self updateConnectionSpeed];
    //NSLog(@"CONNECTION SPEED ENUM = %d", connectionSpeed_);
}

-(void)reset
{
    downloadCount_ = 0;
    averageDownloadDuration_ = 0;
    downloadDurationAccumulator_ = 0.0;
    connectionSpeed_ = CONNECTION_SPEED_NORMAL;
    accumulatorStartInterval_ = [NSDate timeIntervalSinceReferenceDate];
}

-(void)updateConnectionSpeed
{
    // Uncomment the line below to fake out a low speed connection
    // averageDownloadDuration_ *= 10;
    
    if (averageDownloadDuration_ > 0) {
        if(averageDownloadDuration_ < 0.2){
            connectionSpeed_ = CONNECTION_SPEED_VERYHIGH;
        }else if(averageDownloadDuration_ < 0.4){
            connectionSpeed_ = CONNECTION_SPEED_HIGH;
        }else if(averageDownloadDuration_ < 0.7){
            connectionSpeed_ = CONNECTION_SPEED_NORMAL;
        }else if(averageDownloadDuration_ < 1.1){
            connectionSpeed_ = CONNECTION_SPEED_LOW;
        }else if(averageDownloadDuration_ < 1.6){
            connectionSpeed_ = CONNECTION_SPEED_VERYLOW;
        }
    }else{
        connectionSpeed_ = CONNECTION_SPEED_VERYLOW;
    }
    
    self.maxConcurrentOperationCount = [self getMaxConcurrentOperationCountForConnectionSpeed];
    self.imageResolutionMultiplier = [self getImageResolutionMultiplierForConnectionSpeed];
}

-(NSInteger)getMaxConcurrentOperationCountForConnectionSpeed
{
    switch (connectionSpeed_) {
        case CONNECTION_SPEED_VERYLOW:
            return 2;
        case CONNECTION_SPEED_LOW:
            return 4;
        case CONNECTION_SPEED_NORMAL:
            return 6;
        case CONNECTION_SPEED_HIGH:
            return 8;
        case CONNECTION_SPEED_VERYHIGH:
            return 10;
        default:
            return 2;
    }
}

-(float)getImageResolutionMultiplierForConnectionSpeed
{
    // Don't enable this unless the code which loads cached files is updated to load
    // any cached file of higher resolution than that being requested.
    // (otherwise a drop in connection speed could cause a lower res file to be
    // downloaded and used even though a higher res file was already cached)
    return 1;
    
    switch (connectionSpeed_) {
        case CONNECTION_SPEED_VERYLOW:
            return 0.25;
        case CONNECTION_SPEED_LOW:
            return 0.5;
        case CONNECTION_SPEED_NORMAL:
        case CONNECTION_SPEED_HIGH:
        case CONNECTION_SPEED_VERYHIGH:
        default:
            return 1.0;
    }
}

@end
