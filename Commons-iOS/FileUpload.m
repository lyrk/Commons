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
 */
- (void)fetchThumbnailOnCompletion:(void(^)(UIImage *image))block onFailure:(void(^)(NSError *))failureBlock
{
    CommonsApp *app = CommonsApp.singleton;;
    if (self.complete.boolValue) {
        [app fetchImageURL:[NSURL URLWithString:self.thumbnailURL]
              onCompletion:block
                 onFailure:failureBlock];
    } else {
        // Use the pre-uploaded file as the medium thumbnail
        [app loadImage:self.localFile
              fileType:self.fileType
          onCompletion:block];
    }
}

/**
 * Fetch thumbnail data and save to the record
 */
- (void)saveThumbnailOnCompletion:(void(^)())block onFailure:(void(^)(NSError *))failureBlock
{
    CommonsApp *app = CommonsApp.singleton;
    MWApi *api = [app startApi];
    [api getRequest:@{
     @"action": @"query",
     @"titles": [@"File:" stringByAppendingString:self.title],
     @"prop": @"imageinfo",
     @"iiprop": @"timestamp|url",
     @"iiurlwidth": @"640",
     @"iiurlheight": @"640"
     }
       onCompletion:^(MWApiResult *result) {
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
           block();
       }
          onFailure:failureBlock];
}

@end
