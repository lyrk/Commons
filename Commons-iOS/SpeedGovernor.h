//
//  SpeedGovernor.h
//  Commons-iOS
//
//  Created by Monte Hurd on 5/8/13.

#import <Foundation/Foundation.h>

@interface SpeedGovernor : NSObject

// Simply tell SpeedGovernor how long downloads are taking
- (void)reportDownloadDuration:(NSTimeInterval)downloadDuration;

// Then ask it how many concurrent downloads should be attempted
@property (nonatomic) NSInteger maxConcurrentOperationCount;

// Or ask it if the image resolution to be requested should be reduced
@property (nonatomic) float imageResolutionMultiplier;

@end
