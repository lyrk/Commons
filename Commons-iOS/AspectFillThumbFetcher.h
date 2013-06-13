//
//  AspectFillThumbFetcher.h
//  Commons-iOS
//
//  Created by Monte Hurd on 6/12/13.

#import <Foundation/Foundation.h>

@class MWPromise;
@interface AspectFillThumbFetcher : NSObject

- (MWPromise *)fetchThumbnail:(NSString *)filename size:(CGSize)size withQueuePriority:(NSOperationQueuePriority)priority;
- (MWPromise *)fetchPictureOfDay:(NSString *)dateString size:(CGSize)size withQueuePriority:(NSOperationQueuePriority)priority;

@end
