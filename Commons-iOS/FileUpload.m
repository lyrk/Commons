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

@dynamic categories;
@dynamic complete;
@dynamic created;
@dynamic desc;
@dynamic localFile;
@dynamic fileType;
@dynamic title;
@dynamic progress;
@dynamic source;
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
        CGSize size = CGSizeMake(640.0f, 640.0f); // hmm
        fetch = [app fetchWikiImage:self.title size:size];
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


- (BOOL)isReadyForUpload
{
    return self.complete.boolValue == NO &&
           self.title.length > 0 &&
           self.desc.length > 0;
}

- (NSArray *)categoryList
{
    if (self.categories == nil) {
        return @[];
    } else {
        return [self.categories componentsSeparatedByString: @"|"];
    }
}

@end
