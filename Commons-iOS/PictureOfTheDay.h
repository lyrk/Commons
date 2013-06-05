//
//  PictureOfTheDay.h
//  Commons-iOS
//
//  Created by Monte Hurd on 5/30/13.

#import <Foundation/Foundation.h>

@interface PictureOfTheDay : NSObject

@property (strong, nonatomic) void(^done)(NSDictionary *imageData);
@property (strong, nonatomic) NSString *dateString;

-(void)getAtSize:(CGSize)size;
-(NSString *)getDateStringForDaysAgo:(int)daysAgo;

@end
