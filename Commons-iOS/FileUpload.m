//
//  FileUpload.m
//  Commons-iOS
//
//  Created by Brion on 1/25/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "FileUpload.h"
#import "CommonsApp.h"
#import "ImageResizer.h"

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

@synthesize fetchThumbnailProgress;

#define THUMBNAIL_RESOLUTION_IPAD 480.0f
#define THUMBNAIL_RESOLUTION_NON_IPAD 320.0f

- (id)initWithEntity:(NSEntityDescription *)entity insertIntoManagedObjectContext:(NSManagedObjectContext *)context{
    
    self.fetchThumbnailProgress = @0.0f;
    
    return [super initWithEntity:entity insertIntoManagedObjectContext:context];
}

- (NSString *)prettySize
{
    float megs = (float)self.fileSize.integerValue / (1024.0f * 1024.0f);
    return [NSString stringWithFormat:@"%0.1f MB", megs];
}

/**
 * Fetch the local or remote thumbnail saved for this record.
 * Sends a UIImage to the completion callback.
 */
- (MWPromise *)fetchThumbnailWithQueuePriority:(NSOperationQueuePriority)priority
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
        
        // Generate local thumbnail so it doesn't require round-trip to server after uploading
        ImageResizer *imageResizer = [[ImageResizer alloc] init];
        imageResizer.imagePath = [app filePath:self.localFile];
        imageResizer.thumbImagePath = [app thumbPath:
                                       [NSString stringWithFormat:@"%dx%d-%@", (int)size.width, (int)size.height, self.title]
                                       ];
        imageResizer.desiredSize = size;
        [imageResizer createThumbImage];
        
        fetch = [app fetchWikiImage:self.title size:size withQueuePriority:priority];
    } else {
        // Use the pre-uploaded file as the medium thumbnail
        fetch = [app loadImage:self.localFile
                      fileType:self.fileType];
    }

    [fetch progress:^(NSDictionary *dict) {
        // Set fetchThumbnailProgress so it can be queried to determine how much progress was previously made
        // (this is needed, for example, when a cell appears and partially downloads, but then the cell goes
        // off-screen, then back on-screen. When it comes back on-screen there may be a period of time before
        // new progress is reported. Having this fetchThumbnailProgress value lets us make the progress
        // indicator display the previous progress even before it gets another progress callback)
        NSNumber *bytesReceived = dict[@"received"];
        NSNumber *bytesTotal = dict[@"total"];
        
        if (bytesTotal.floatValue > 0.0f) {
            self.fetchThumbnailProgress = @(bytesReceived.floatValue / bytesTotal.floatValue);
        }
        
        [deferred notify:dict];
    }];
    
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
