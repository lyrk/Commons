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

- (NSArray *)categoryList
{
    if (self.categories == nil || self.categories.length == 0) {
        return @[];
    } else {
        return [self.categories componentsSeparatedByString: @"|"];
    }
}

- (void)addCategory:(NSString *)category
{
    NSMutableArray *cats = [self.categoryList mutableCopy];
    BOOL alreadyHave = NO;

    for (NSString *cat in cats) {
        if ([cat isEqualToString:category]) {
            alreadyHave = YES;
        }
    }
    
    if (!alreadyHave) {
        [cats addObject:category];
        self.categories = [cats componentsJoinedByString:@"|"];
    }
}

- (void)removeCategory:(NSString *)category
{
    NSMutableArray *cats = [self.categoryList mutableCopy];
    NSInteger index = -1;
    
    for (NSInteger i = 0; i < cats.count; i++) {
        NSString *cat = cats[i];
        if ([cat isEqualToString:category]) {
            index = i;
        }
    }
    
    if (index > -1) {
        [cats removeObjectAtIndex:index];
        self.categories = [cats componentsJoinedByString:@"|"];
    }
}


@end
