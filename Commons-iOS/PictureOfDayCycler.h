//
//  PictureOfDayCycler.h
//  Commons-iOS
//
//  Created by Monte Hurd on 6/12/13.

#import <Foundation/Foundation.h>

@interface PictureOfDayCycler : NSObject

@property(weak, nonatomic) NSMutableArray *dateStrings;

@property(copy) void(^cycle)(NSString *dateString);

@property(nonatomic) float displayInterval;
@property(nonatomic) float transitionDuration;

-(void)start;
-(void)stop;

@end
