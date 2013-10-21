//
//  PictureOfDayCycler.h
//  Commons-iOS
//
//  Created by Monte Hurd on 6/12/13.

#import <Foundation/Foundation.h>

@interface PictureOfDayCycler : NSObject

@property(strong, nonatomic) NSMutableArray *dateStrings;
@property(strong, nonatomic, readonly) NSString *currentDateString;
@property(nonatomic) NSUInteger currentDateStringIndex;

@property(copy) void(^cycle)(NSString *dateString);

@property(nonatomic) float displayInterval;
@property(nonatomic) float transitionDuration;

-(void)start;
-(void)stop;

@end
