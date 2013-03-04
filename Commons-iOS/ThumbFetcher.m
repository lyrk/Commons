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

    if (requests_.count == 50) {
        // We're nearing the maximum request size. Batch one off!
        [self fetchQueuedThumbnails];
    } else if (queued_) {
        // We've already requested a thumb, we're still waiting in case we get a couple more.
    } else {
        queued_ = YES;

        // Delay a little bit waiting for more ...
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_queue_t queue = dispatch_get_main_queue();
        dispatch_after(popTime, queue, ^(){
            [self fetchQueuedThumbnails];
        });
    }
    
    return deferred.promise;
}

- (MWPromise *)fetchQueuedThumbnails
{
    CommonsApp *app = CommonsApp.singleton;
    MWApi *api = [app startApi];
    MWDeferred *deferred = [[MWDeferred alloc] init];

    if (requests_.count == 0) {
        return nil;
    }

    // Grab the queued requests and clear the queue...
    NSMutableArray *entries = requests_;
    requests_ = [[NSMutableArray alloc] init];
    queued_ = NO;

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
        NSDictionary *pages = result[@"query"][@"pages"];
        for (NSString *pageId in pages) {
            NSDictionary *page = pages[pageId];
            NSString *title = page[@"title"];

            NSDictionary *imageinfo = page[@"imageinfo"][0];
            NSURL *thumbnailURL = [NSURL URLWithString:imageinfo[@"thumburl"]];
            
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
