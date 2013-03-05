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
    NSMutableDictionary *requestsByKey_;
    NSMutableDictionary *urlsByKey_;
    BOOL queued_;
}
@end

@implementation ThumbFetcher

- (id)init
{
    self = [super init];
    if (self) {
        requests_ = [[NSMutableArray alloc] init];
        requestsByKey_ = [[NSMutableDictionary alloc] init];
        urlsByKey_ = [[NSMutableDictionary alloc] init];
        queued_ = NO;
    }
    return self;
}

- (MWPromise *)fetchThumbnail:(NSString *)filename size:(CGSize)size
{
    NSString *sizeKey = [NSString stringWithFormat:@"%dx%d", (int)size.width, (int)size.height];
    NSString *key = [NSString stringWithFormat:@"%@-%@", sizeKey, filename];
    NSDictionary *entry = requestsByKey_[key];
    if (entry) {
        // We're already requesting this one... piggyback the existing request.
        return ((MWDeferred *)entry[@"deferred"]).promise;
    }

    MWDeferred *deferred = [[MWDeferred alloc] init];
    entry = @{
              @"key": key,
              @"filename": filename,
              @"width": [NSString stringWithFormat:@"%d", (int)size.width],
              @"height": [NSString stringWithFormat:@"%d", (int)size.height],
              @"deferred": deferred
              };

    requestsByKey_[key] = entry;

    NSURL *url = urlsByKey_[key];
    if (url) {
        // We already know the URL but haven't started fetching it.
        [self fetchImageByKey:key];
        return deferred.promise;
    }

    // We have to look up the proper URL; add it to the queue.
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
    for (NSDictionary *entry in entries) {
        NSString *title = [@"File:" stringByAppendingString:entry[@"filename"]];
        [buildTitles addObject:title];

        // Fixme handle images of different sizes :)
        width = entry[@"width"];
        height = entry[@"height"];
    }
    NSString *sizeKey = [NSString stringWithFormat:@"%@x%@", width, height];
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
            NSString *title = [app cleanupTitle:page[@"title"]];
            NSString *key = [NSString stringWithFormat:@"%@-%@", sizeKey, title];

            NSDictionary *imageinfo = page[@"imageinfo"][0];
            NSURL *thumbnailURL = [NSURL URLWithString:imageinfo[@"thumburl"]];
            
            if (thumbnailURL) {
                urlsByKey_[key] = thumbnailURL;
            }
            [self fetchImageByKey:key];
        }
        [deferred resolve:result];
    }];
    [fetch fail:^(NSError *err) {
        NSLog(@"fetch failed");
        [deferred reject:err];
        // fixme reject all the individual deferreds
    }];
    
    return deferred.promise;
}

- (void)fetchImageByKey:(NSString *)key
{
    CommonsApp *app = CommonsApp.singleton;
    MWDeferred *fetchDeferred = requestsByKey_[key][@"deferred"];
    NSURL *thumbnailURL = urlsByKey_[key];
    
    if (thumbnailURL) {
        MWPromise *fetchImage = [app fetchImageURL:thumbnailURL];
        [fetchImage done:^(UIImage *image) {
            [requestsByKey_ removeObjectForKey:key];
            [fetchDeferred resolve:image];
        }];
        [fetchImage fail:^(NSError *error) {
            [requestsByKey_ removeObjectForKey:key];
            [fetchDeferred reject:error];
        }];
    } else {
        NSError *error = [NSError errorWithDomain:@"MediaWiki" code:200 userInfo:@{}];
        [fetchDeferred reject:error];
    }
}
@end
