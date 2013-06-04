//
//  PictureOfTheDay.h
//  Commons-iOS
//
//  Created by Monte Hurd on 5/30/13.

#import <Foundation/Foundation.h>

@interface PictureOfTheDay : NSObject

@property (strong, nonatomic) void(^done)(NSDictionary *imageData);

-(void)getAtSize:(CGSize)size;

@end
