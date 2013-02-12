//
//  FileUpload.m
//  Commons-iOS
//
//  Created by Brion on 1/25/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "FileUpload.h"
#import "CommonsApp.h"

@implementation FileUpload

@dynamic complete;
@dynamic created;
@dynamic desc;
@dynamic localFile;
@dynamic fileType;
@dynamic title;
@dynamic progress;
@dynamic thumbnailURL;
@dynamic fileSize;

- (NSString *)prettySize
{
    float megs = (float)self.fileSize.integerValue / (1024.0f * 1024.0f);
    return [NSString stringWithFormat:@"%0.1f MB", megs];
}

/**
 * Fetch the local or remote thumbnail saved for this record.
 * Sends a UIImage to the completion callback.
 */
- (MWPromise *)fetchThumbnail
{
    CommonsApp *app = CommonsApp.singleton;;
    MWDeferred *deferred = [[MWDeferred alloc] init];
    MWPromise *fetch;

    if (self.complete.boolValue) {
        fetch = [app fetchImageURL:[NSURL URLWithString:self.thumbnailURL]];
    } else {
        // Use the pre-uploaded file as the medium thumbnail
        fetch = [app loadImage:self.localFile
                      fileType:self.fileType];
    }
    
    [fetch done:^(UIImage *image) {
        [deferred resolve:image];
    }];
    [fetch fail:^(NSError *err) {
        [deferred reject:err];
    }];
    return deferred.promise;
}

/**
 * Fetch thumbnail data and save to the record
 */
- (MWPromise *)saveThumbnail
{
    CommonsApp *app = CommonsApp.singleton;
    MWDeferred *deferred = [[MWDeferred alloc] init];
    MWApi *api = [app startApi];

    MWPromise *fetch = [api getRequest:@{
         @"action": @"query",
         @"titles": [@"File:" stringByAppendingString:self.title],
         @"prop": @"imageinfo",
         @"iiprop": @"timestamp|url",
         @"iiurlwidth": @"640",
         @"iiurlheight": @"640"
    }];
    [fetch done:^(MWApiResult *result) {
        NSLog(@"thumbnail info: %@", result.data);
        NSDictionary *pages = result.data[@"query"][@"pages"];
        for (NSString *pageId in pages) {
            NSDictionary *page = pages[pageId];
            NSDictionary *imageinfo = page[@"imageinfo"][0];
 
            self.complete = @YES;
            self.title = [app cleanupTitle:page[@"title"]];
            self.created = [app decodeDate:imageinfo[@"timestamp"]];
            self.thumbnailURL = imageinfo[@"thumburl"];
 
            NSLog(@"got thumb URL %@", self.thumbnailURL);
        }
        [app saveData];
        [deferred resolve:result];
    }];
    [fetch fail:^(NSError *err) {
        [deferred reject:err];
    }];

    return deferred.promise;
}

@end
