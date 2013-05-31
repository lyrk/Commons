//
//  PictureOfTheDay.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/30/13.

#import "PictureOfTheDay.h"
#import "ThumbFetcher.h"
#import "CommonsApp.h"

@implementation PictureOfTheDay{
    NSURL *potdURL_;
    UIImage *potdImage_;
    ThumbFetcher *thumbFetcher_;
}

- (id)init
{
    self = [super init];
    if (self) {
        thumbFetcher_ = [[ThumbFetcher alloc] init];
        potdURL_ = nil;
        potdImage_ = nil;
    }
    return self;
}

-(NSURL *)getJsonUrl
{
    NSDate *date = [[NSDate alloc] init];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *urlStr = [NSString stringWithFormat:
    @"http://en.wikipedia.org/w/api.php?action=query&generator=images&prop=imageinfo&titles=Template:POTD/%@&iiprop=url&format=json", [formatter stringFromDate:date]];
    return [NSURL URLWithString:urlStr];
}

-(void)getAtSize:(CGSize)size;
{
    // Retrieves thumbnail of the picture of the day. Caches it and use the cached file next time.
    CommonsApp *app = CommonsApp.singleton;
    
    NSError *err = nil;
    NSData *urlData = [NSData dataWithContentsOfURL:[self getJsonUrl] options:nil error:&err];
    if (err){
        [self loadBundledDefaultPictureOfTheDay];
        return;
    }

    err = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:urlData options:kNilOptions error:&err];
    if (err){
        [self loadBundledDefaultPictureOfTheDay];
        return;
    }

    // Find the potdURL_ in the json data
    NSString *urlStr = nil;
    [self enumerateJSON:json currentKey:nil findKey:@"url" result:&urlStr];
    if (!urlStr) {
        NSLog(@"Could not locate Picture of the Day URL.");
        [self loadBundledDefaultPictureOfTheDay];
        return;
    }
    potdURL_ = [NSURL URLWithString:urlStr];
    //NSLog(@"potd json = %@", json);
    
    // Test with very wide image:
    // (this should trigger isAspectRatioOkForSize: to return NO so the bundled image will be shown
    // so to truly test how bad a crazy wide image looks force isAspectRatioOkForSize: to return YES)
    // http://commons.wikimedia.org/wiki/File:Perth_CBD_from_Mill_Point.jpg
    //potdURL_ = [NSURL URLWithString:@"/wikipedia/commons/e/e6/Perth_CBD_from_Mill_Point.jpg"];

    // This image isn't so wide
    //potdURL_ = [NSURL URLWithString:@"wikipedia/commons/b/b7/Honeymoon_Bay_Sunset_2.jpg"];
    
    NSString *filename = [[potdURL_ path] lastPathComponent];
    NSString *sizeKey = [NSString stringWithFormat:@"%dx%d", (int)size.width, (int)size.height];
    
    NSLog(@"FILE NAME = %@", filename);
    NSString *key = [NSString stringWithFormat:@"%@-%@", sizeKey, filename];
    UIImage *image = [thumbFetcher_ cachedThumbForKey:key];
    if (image) {
        // Cached image located. Use it.
        self.done(image);
    }else{
        if (!filename) {
            [self loadBundledDefaultPictureOfTheDay];
            return;
        }
        MWApi *api = [app startApi];
        // Request the thumbnail be generated
        MWPromise *fetch = [api getRequest:@{
                             @"action": @"query",
                             @"titles": [@"File:" stringByAppendingString:filename],
                             @"prop": @"imageinfo",
                             @"iiprop": @"timestamp|url",
                             @"iiurlwidth": @((int)size.width),
                             @"iiurlheight": @((int)size.height)
                             }];
        [fetch done:^(NSDictionary *result) {
            //NSLog(@"potd fetch = %@", result);
            
            // Examine the reported width and height of the image so its aspect ratio can be
            // calculated to see if it's a good fit. If it's an extremely wide panorama it is not
            NSString *potdWidth = nil;
            NSString *potdHeight = nil;
            [self enumerateJSON:result currentKey:nil findKey:@"thumbwidth" result:&potdWidth];
            [self enumerateJSON:result currentKey:nil findKey:@"thumbheight" result:&potdHeight];
            if (potdWidth && potdHeight) {
                if (![self isAspectRatioOkForSize:CGSizeMake(potdWidth.floatValue, potdHeight.floatValue)]) {
                    // If extreme panorama use bundled image
                    [self loadBundledDefaultPictureOfTheDay];
                    return;
                }
            }else{
                // If size could not be determined use bundled image
                [self loadBundledDefaultPictureOfTheDay];
                return;
            }
            
            NSDictionary *pages = result[@"query"][@"pages"];
            for (NSString *pageId in pages) {
                NSDictionary *page = pages[pageId];
                NSDictionary *imageinfo = page[@"imageinfo"][0];
                NSURL *potdThumbnailURL = [NSURL URLWithString:imageinfo[@"thumburl"]];
                if (potdThumbnailURL) {
                    // Now request the generated thumbnail
                    MWPromise *fetchImage = [app fetchDataURL:potdThumbnailURL];
                    [fetchImage done:^(NSData *data) {
                        [thumbFetcher_ cacheImageData:data forKey:key];
                        UIImage *image = [UIImage imageWithData:data scale:1.0];
                        // Thumbnail retrieved. Use it.
                        self.done(image);
                    }];
                    [fetchImage fail:^(NSError *error) {
                        [self loadBundledDefaultPictureOfTheDay];
                    }];
                    [fetchImage progress:^(id arg) {
                        
                    }];
                }
            }
        }];
    }
}

-(BOOL)isAspectRatioOkForSize:(CGSize)size
{
    float r = size.width / size.height;
    if (r < 1.0f) r = 1.0f / r;
    // If the image is more than twice as wide as it is tall, or more than twice at tall as it is wide, then
    // its not ok to use because only a small part of the thumb will end up being onscreen because aspect fill
    // is being used to ensure the entire background of the login view controller's view is filled with image
    return (r > 2.0f) ? NO : YES;
}

-(void)loadBundledDefaultPictureOfTheDay
{
    UIImage *bundledDefaultPicOfDay = [UIImage imageNamed:@"Default-Pic-Of-Day.jpg"];
    self.done(bundledDefaultPicOfDay);
}

// Based on: http://stackoverflow.com/a/15811405/135557
// Could use some refactoring
- (void)enumerateJSON:(id)object currentKey:(NSString *)currentKey findKey:(NSString *)soughtKey result:(NSString **)result
{
    if ([object isKindOfClass:[NSDictionary class]]){
        // If it's a dictionary, enumerate it and pass in each key value to check
        [object enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
            [self enumerateJSON:value currentKey:key findKey:soughtKey result:result];
        }];
    }else if ([object isKindOfClass:[NSArray class]]){
        // If it's an array, pass in the objects of the array to check
        [object enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [self enumerateJSON:obj currentKey:nil findKey:soughtKey result:result];
        }];
    }else{
        if ([currentKey isEqualToString:soughtKey]) {
            // If we got here (i.e. it's not a dictionary or array) so its a key/value that we needed
            //urlStr = @"http://upload.wikimedia.org/wikipedia/foundation/9/9a/Wikimediafoundation-logo.png";
            *result = (NSString *)object;
        }
    }
}

@end
