//
//  ThumbFetcher.m
//  Commons-iOS
//
//  Created by Brion on 3/4/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "ThumbFetcher.h"
#import "CommonsApp.h"

@interface ThumbFetcher() {
    NSMutableArray *requests_;
    BOOL queued_;
}
@end

@implementation ThumbFetcher

- (id)init
{
    self = [super init];
    if (self) {
        requests_ = [[NSMutableArray alloc] init];
        queued_ = NO;
    }
    return self;
}

- (MWPromise *)fetchThumbnail:(NSString *)filename size:(CGSize)size
{
    MWDeferred *deferred = [[MWDeferred alloc] init];
    
    NSDictionary *entry = @{
                            @"filename": filename,
                            @"width": [NSString stringWithFormat:@"%d", (int)size.width],
                            @"height": [NSString stringWithFormat:@"%d", (int)size.height],
                            @"deferred": deferred
                            };

    [requests_ addObject:entry];

    // fixme: delay a little bit so we can capture multiple adjacent images
    [self fetchQueuedThumbnails];
    
    return deferred.promise;
}

- (MWPromise *)fetchQueuedThumbnails
{
    NSLog(@"fetchQueuedThumbnails");
    CommonsApp *app = CommonsApp.singleton;
    MWApi *api = [app startApi];
    MWDeferred *deferred = [[MWDeferred alloc] init];

    // Grab the queued requests and clear the queue...
    NSMutableArray *entries = requests_;
    requests_ = [[NSMutableArray alloc] init];

    NSString *width, *height;
    NSMutableArray *buildTitles = [[NSMutableArray alloc] init];
    NSMutableDictionary *deferreds = [[NSMutableDictionary alloc] init];
    for (NSDictionary *entry in entries) {
        NSString *title = [@"File:" stringByAppendingString:entry[@"filename"]];
        [buildTitles addObject:title];
        deferreds[title] = entry[@"deferred"];

        // Fixme handle images of different sizes :)
        width = entry[@"width"];
        height = entry[@"height"];
    }
    NSString *titles = [buildTitles componentsJoinedByString:@"|"];

    NSLog(@"fetching for titles: %@", titles);
    MWPromise *fetch = [api getRequest:@{
                        @"action": @"query",
                        @"titles": titles,
                        @"prop": @"imageinfo",
                        @"iiprop": @"timestamp|url",
                        @"iiurlwidth": width,
                        @"iiurlheight": height
                        }];
    [fetch done:^(NSDictionary *result) {
        NSLog(@"fetch done");
        NSDictionary *pages = result[@"query"][@"pages"];
        for (NSString *pageId in pages) {
            NSDictionary *page = pages[pageId];
            NSString *title = page[@"title"];

            NSDictionary *imageinfo = page[@"imageinfo"][0];
            NSURL *thumbnailURL = [NSURL URLWithString:imageinfo[@"thumburl"]];
            
            NSLog(@"got thumb URL %@ for %@", thumbnailURL, title);

            MWDeferred *fetchDeferred = deferreds[title];
            MWPromise *fetchImage = [app fetchImageURL:thumbnailURL];
            [fetchImage done:^(UIImage *image) {
                [fetchDeferred resolve:image];
            }];
            [fetchImage fail:^(NSError *error) {
                [fetchDeferred reject:error];
            }];
        }
        [deferred resolve:result];
    }];
    [fetch fail:^(NSError *err) {
        NSLog(@"fetch failed");
        [deferred reject:err];
    }];
    
    return deferred.promise;
}

@end
