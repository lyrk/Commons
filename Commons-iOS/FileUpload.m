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
@dynamic source;
@dynamic thumbnailURL;
@dynamic fileSize;

#define THUMBNAIL_RESOLUTION_IPAD 256.0f
#define THUMBNAIL_RESOLUTION_NON_IPAD 320.0f

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
        float resolution = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? THUMBNAIL_RESOLUTION_IPAD : THUMBNAIL_RESOLUTION_NON_IPAD;
        resolution *= [[UIScreen mainScreen] scale];
        
        // Ask the speedGovernor what image resolution mulitiplier is suited to the current connection speed
        resolution *= app.speedGovernor.imageResolutionMultiplier;
        
        CGSize size = CGSizeMake(resolution, resolution);
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

@end
