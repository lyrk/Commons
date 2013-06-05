//
//  PictureOfTheDay.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/30/13.

#import "PictureOfTheDay.h"
#import "CommonsApp.h"

#define POTD_MAX_W_H_RATIO 2.0f

@implementation PictureOfTheDay

-(NSString *)getDateStringForDaysAgo:(int)daysAgo
{
    NSDate *date = [[NSDate alloc] init];
    date = [date dateByAddingTimeInterval: -(86400.0 * daysAgo)];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    return [formatter stringFromDate:date];
}

-(NSString *)potdCacheFileName
{    
    return [NSString stringWithFormat:@"POTD-%@", self.dateString];
}

-(NSURL *)getJsonUrl
{    
    NSString *urlStr = [NSString stringWithFormat:
        @"http://commons.wikimedia.org/w/api.php?action=query&generator=images&prop=imageinfo&titles=Template:Potd/%@&iiprop=url|size|comment|metadata|user|userid&format=json", self.dateString];
    
    return [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

-(void)getAtSize:(CGSize)size;
{
    // Retrieves thumbnail of the picture of the day. Caches it and use the cached file next time.
    void (^retrievedJsonUrlData)(NSURLResponse*, NSData*, NSError*) = ^(NSURLResponse *response, NSData *urlData, NSError *err) {
        if (err) return;
        
        err = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:urlData options:kNilOptions error:&err];
        if (err) return;
        
        if (!json.count){
            NSLog(@"No json data received for the url above ^");
            return;
        }
        
        // Find the potdURL in the json data
        NSString *urlStr = [self getValueForKey:@"url" fromJson:json];
        
        if (!urlStr) {
            NSLog(@"Could not locate Picture of the Day URL.\nURL = %@", urlStr);
            return;
        }
        
        NSString *user = [self getValueForKey:@"user" fromJson:json];
        NSLog(@"PotD from User = %@", user);
        
        NSDictionary *metadata = [self getMetadataFromJson:json];
        NSLog(@"PotD Metadata = %@", metadata);
        //NSLog(@"PotD Camera Model = %@", metadata[@"Model"]);
        
        // Determine the height and width of the picture of the day from the json data
        // (The size needs to be know before the thumb is requested because the thumb needs
        // to be sized to best fit the present device screen dimensions)
        CGSize originalSize = [self getSizeFromJson:json];
        
        // Uncomment to simulate extreme panorama
        //originalSize.width = originalSize.width * 3;
        
        // Examine the reported width and height of the image so its aspect ratio can be
        // calculated to see if it's a good fit. If it's an extremely wide panorama (vertical
        // or horizontal) then it is not
        if (![self isAspectRatioOkForSize:CGSizeMake(originalSize.width, originalSize.height)]) return;

        NSString *filename = [self pageIdNodeFromJson:json][@"title"];
        
        if (!filename) return;
        
        NSString *key = [self potdCacheFileName];

        // Request the thumbnail be generated
        MWApi *api = [CommonsApp.singleton startApi];
        
        NSMutableDictionary *params = [@{
                                   @"action": @"query",
                                   @"titles": filename,
                                   @"prop": @"imageinfo",
                                   @"iiprop": @"timestamp|url"
                                   } mutableCopy];

        // If the image is more wide than tall get thumb at screen height
        if (originalSize.width > originalSize.height) {
            params[@"iiurlheight"] = @((int)size.height);
        }else{
        // If the image is more tall than wide get thumb at screen width
            params[@"iiurlwidth"] = @((int)size.width);
        }
        
        MWPromise *fetch = [api getRequest:params];
        [fetch done:^(NSDictionary *result) {
            //NSLog(@"potd fetch = %@", result);
            
            //NSString *thumbWidth = [self getValueForKey:@"thumbwidth" fromJson:result];
            //NSString *thumbHeight = [self getValueForKey:@"thumbheight" fromJson:result];

            NSURL *potdThumbnailURL = [NSURL URLWithString:[self getValueForKey:@"thumburl" fromJson:result]];
            if (potdThumbnailURL) {
                // Now request the generated thumbnail
                MWPromise *fetchImage = [CommonsApp.singleton fetchDataURL:potdThumbnailURL withQueuePriority:NSOperationQueuePriorityNormal];
                [fetchImage done:^(NSData *data) {
                    // Cache the image data
                    NSDictionary *imageDataDict = @{@"image": data, @"user": user, @"metadata": metadata, @"date": self.dateString};
                    [self cachePotdDict:imageDataDict forKey:key];
                    // Make all of the image data available to the callback
                    self.done(imageDataDict);
                }];
                [fetchImage fail:^(NSError *error) {
                }];
                [fetchImage progress:^(id arg) {
                }];
            }
        }];
    };

    NSDictionary *cachedImageDataDict = [self cachedPotdDictForKey: [self potdCacheFileName]];
    if (cachedImageDataDict) {
        // Cached image located. Use it.
        self.done(cachedImageDataDict);
    }else{
        // Get json data for today's picture asynchronously
        NSURL * url = [self getJsonUrl];
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
        
        NSLog(@"Retrieving json data from url %@", url);
        
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:retrievedJsonUrlData];
        /*
        // Get json data for today's picture synchronously
        NSError *err = nil;
        NSData *urlData = [NSData dataWithContentsOfURL:[self getJsonUrl] options:nil error:&err];
        retrievedJsonUrlData(nil, urlData, err);
        */
    }
}

- (NSDictionary *)cachedPotdDictForKey:(NSString *)key
{
    NSString *imgDataPath = [self potdPath:key];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:imgDataPath]) {
        NSData *data = [NSData dataWithContentsOfFile:imgDataPath options:nil error:nil];
        return (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
    } else {
        return nil;
    }
}

- (NSString *)potdPath:(NSString *)fileName
{
    return [[[CommonsApp singleton] documentRootPath] stringByAppendingFormat:@"/potd/%@", fileName];
}

- (void)cachePotdDict:(NSDictionary *)dict forKey:(NSString *)key
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
    [data writeToFile:[self potdPath:key] atomically:YES];
}

-(BOOL)isAspectRatioOkForSize:(CGSize)size
{
    //return YES;
    
    // Avoid zero division errors
    size.width += 0.00001f;
    size.height += 0.00001f;
    
    float r = size.width / size.height;
    if (r < 1.0f) r = 1.0f / r;
    // If the image is more than POTD_MAX_W_H_RATIO as wide as it is tall, or more than POTD_MAX_W_H_RATIO as
    // tall as it is wide, then its not ok to use because only a small part of the thumb will end up being
    // onscreen because aspect fill is being used to ensure the entire background of the login view
    //controller's view is filled with image
    BOOL result = (r > POTD_MAX_W_H_RATIO) ? NO : YES;
    if (!result) {
        NSLog(@"isAspectRatioOkForSize: Detected Extreme Panorama!");
    }
    return result;
}

-(CGSize)getSizeFromJson:(NSDictionary *)json
{
    // Determine the height and width of the picture of the day from the json data
    NSString *origHeight = [self getValueForKey:@"height" fromJson:json];
    NSString *origWidth = [self getValueForKey:@"width" fromJson:json];
    return (origHeight && origWidth) ? CGSizeMake(origWidth.floatValue, origHeight.floatValue) : CGSizeZero;
}

-(id)pageIdNodeFromJson:(NSDictionary *)json
{
    return [[json[@"query"][@"pages"] allValues] objectAtIndex:0];
}

-(id)getValueForKey:(NSString *)key fromJson:(NSDictionary *)json
{
    id result = nil;
    @try{
        result = [[self pageIdNodeFromJson:json][@"imageinfo"] objectAtIndex:0][key];
    }@catch(id anException){
        NSLog(@"Unexpected JSON structure!");
    }
    return result;
}

-(NSDictionary *)getMetadataFromJson:(NSDictionary *)json
{
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    NSArray *metadata = [self getValueForKey:@"metadata" fromJson:json];
    for (NSDictionary* pair in metadata) {
        result[pair[@"name"]] = pair[@"value"];
    }
    return result;
}

@end
