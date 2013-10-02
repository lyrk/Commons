//
//  AspectFillThumbFetcher.m
//  Commons-iOS
//
//  Created by Monte Hurd on 6/12/13.

#import "AspectFillThumbFetcher.h"
#import "CommonsApp.h"
#import "MWPromise.h"
#import "DescriptionParser.h"
#import "MWI18N.h"
#import "CategoryLicenseExtractor.h"

#pragma mark - Private

@interface AspectFillThumbFetcher ()

// Specifies just the url get "titles" setting which will be used to retrieve image data from the server.
// eg: "File:filename.ext" or "Template:Potd/yyyy-MM-dd" for an image of the day
@property (strong, nonatomic) NSString *getTitle;

// Specifies just the url get "generator" setting which will be used when retrieving image data from the server.
// eg: "images" for image of the day, "" otherwise
@property (strong, nonatomic) NSString *getGenerator;

// Extra key value pairs to be added to the image cache file data
@property (strong, nonatomic) NSDictionary *extraDataToCache;

// Name to be used for cache file
@property (strong, nonatomic) NSString *cacheFileName;

// Path in which to save (and check for) cache file for cacheFileName
@property (strong, nonatomic) NSString *cachePath;

// w/h *and* h/w ratio threshold beyond which image isn't retrieved. 0.0f for no check
@property (nonatomic) float maxWidthHeightRatio;

@end

#pragma mark - Init

@implementation AspectFillThumbFetcher{
    DescriptionParser *descriptionParser_;
    CategoryLicenseExtractor *categoryLicenseExtractor_;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.extraDataToCache = nil;
        self.cacheFileName = nil;
        self.cachePath = nil;
        self.maxWidthHeightRatio = 0.0f;
        self.getTitle = nil;
        self.getGenerator = nil;
        descriptionParser_ = [[DescriptionParser alloc] init];
        categoryLicenseExtractor_ = [[CategoryLicenseExtractor alloc] init];
    }
    return self;
}

#pragma mark - Convenience

- (MWPromise *)fetchThumbnail:(NSString *)filename size:(CGSize)size withQueuePriority:(NSOperationQueuePriority)priority;
{
    MWDeferred *deferred = [[MWDeferred alloc] init];
    
    self.cachePath = [[[CommonsApp singleton] documentRootPath] stringByAppendingFormat:@"/thumbs/"];
    
    self.extraDataToCache = nil;
    
    self.getTitle = [@"File:" stringByAppendingString:filename];
    
    self.getGenerator = @"";
    
    self.cacheFileName = [NSString stringWithFormat:@"%dx%d-%@", (uint)size.width, (uint)size.height, filename];
    
    self.maxWidthHeightRatio = 0.0f;
    
    [self getAtSize:size deferred:deferred];
    
    return deferred.promise;
}

- (MWPromise *)fetchPictureOfDay:(NSString *)dateString size:(CGSize)size withQueuePriority:(NSOperationQueuePriority)priority
{
    MWDeferred *deferred = [[MWDeferred alloc] init];
    
    self.cachePath = [[[CommonsApp singleton] documentRootPath] stringByAppendingFormat:@"/potd/"];
    
    self.extraDataToCache = @{@"potd_date": dateString};
    
    self.getTitle = [@"Template:Potd/" stringByAppendingString:dateString];
    
    self.getGenerator = @"images";
    
    self.cacheFileName = [NSString stringWithFormat:@"POTD-%@", dateString];
    
    self.maxWidthHeightRatio = 2.0f;
    
    [self getAtSize:size deferred:deferred];
    
    return deferred.promise;
}

#pragma mark - URL determination

-(NSURL *)getJsonUrl
{
    NSString *urlStr = [NSString stringWithFormat:
                        @"%@/w/api.php?action=query&prop=imageinfo&iiprop=url|size|comment|metadata|user|userid&format=json&titles=%@%@",
                        [CommonsApp.singleton wikiURLBase],
                        self.getTitle,
                        (self.getGenerator.length > 0) ? [@"&generator=" stringByAppendingString:self.getGenerator] : @""
                        ];

    return [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

- (NSError*)getErrorWithMessage:(NSString *)msg code:(NSInteger)code
{
    return [[NSError alloc] initWithDomain:@"AspectFillThumbFetcher"
                                      code:code
                                  userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(msg, nil)}];
}

#pragma mark - Thumb retrieval

-(void)getAtSize:(CGSize)size deferred:(MWDeferred*) deferred
{
    // Retrieves thumbnail of the image. Caches it and use the cached file next time.
    void (^retrievedJsonUrlData)(NSURLResponse*, NSData*, NSError*) = ^(NSURLResponse *response, NSData *urlData, NSError *err) {
        if (err){
            [deferred reject:err];
            return;
        }
        
        err = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:urlData options:kNilOptions error:&err];
        if (err){
            [deferred reject:err];
            return;
        }
        
        if (!json.count){
            [deferred reject:[self getErrorWithMessage:@"No json data received for the url above ^" code:700]];
            return;
        }
        
        // Find the file URL in the json data
        NSString *urlStr = [self getValueForKey:@"url" fromJson:json];
        
        if (!urlStr) {
            [deferred reject:[self getErrorWithMessage:[@"Could not locate image URL.\nURL = " stringByAppendingString:urlStr] code:701]];
            return;
        }
        
        // Determine the height and width of the image from the json data
        // (The size needs to be know before the thumb is requested because the thumb needs
        // to be sized to best fit the present device screen dimensions)
        CGSize originalSize = [self getSizeFromJson:json];
        
        // Uncomment to simulate extreme panorama
        //originalSize.width = originalSize.width * 3;
        
        // Examine the reported width and height of the image so its aspect ratio can be
        // calculated to see if it's a good fit. If it's an extremely wide panorama (vertical
        // or horizontal) then it is not
        if (![self isAspectRatioOkForSize:CGSizeMake(originalSize.width, originalSize.height)]){
            [deferred reject:[self getErrorWithMessage:@"isAspectRatioOkForSize: Detected Extreme Panorama!" code:702]];
            return;
        }
        
        NSString *filename = [self pageIdNodeFromJson:json][@"title"];
        
        if (!filename){
            [deferred reject:[self getErrorWithMessage:@"No file name found in json data" code:703]];
            return;
        }

        // Request the thumbnail be generated
        MWApi *api = [CommonsApp.singleton startApi];
        
        NSMutableDictionary *params = [@{
                                   @"action": @"query",
                                   @"titles": filename,
                                   @"prop": @"imageinfo|categories|revisions",
                                   @"cllimit": @"max",
                                   @"rvprop": @"content",
                                   @"rvparse": @"1",
                                   @"rvlimit": @"1",
                                   @"rvgeneratexml": @"1",
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
            //NSLog(@"image fetch = %@", result);
            
            //NSString *thumbWidth = [self getValueForKey:@"thumbwidth" fromJson:result];
            //NSString *thumbHeight = [self getValueForKey:@"thumbheight" fromJson:result];

            NSURL *thumbURL = [NSURL URLWithString:[self getValueForKey:@"thumburl" fromJson:result]];
            if (thumbURL) {
                // Now request the generated thumbnail
                MWPromise *fetchImage = [CommonsApp.singleton fetchDataURL:thumbURL withQueuePriority:NSOperationQueuePriorityNormal];
                [fetchImage done:^(NSData *data) {

                    // Get data to cache with image data
                    // (If further information is to be cached, "getDataToCacheFromJson:" would be a nice place to do so)
                    NSMutableDictionary *dataToCache = [self getDataToCacheFromJson:json];

                    // Cache the image data
                    dataToCache[@"image"] = data;

                    // Cache the categories and description
                    dataToCache[@"categories"] = [self getCategoriesFromJson:result];
                    dataToCache[@"description"] = [self getDescriptionFromJson:result];
                    
                    // Cache the license (check categories for license)
                    NSString *license = [categoryLicenseExtractor_ getLicenseFromCategories:dataToCache[@"categories"]];
                    if (license) {
                        dataToCache[@"license"] = license;
                        dataToCache[@"licenseurl"] = [categoryLicenseExtractor_ getURLForLicense:license];
                    }

                    [dataToCache addEntriesFromDictionary:self.extraDataToCache];
                    
                    [self cacheDict:dataToCache forKey:self.cacheFileName];
                    // Make all of the image data available to the callback
                    [deferred resolve:dataToCache];

                }];
                [fetchImage fail:^(NSError *error) {
                    [deferred reject:error];

                }];
                [fetchImage progress:^(id arg) {
                }];
            }
        }];
    };

    NSDictionary *cachedImageDataDict = [self cachedDictForKey: self.cacheFileName];

    if (cachedImageDataDict) {
        // Cached image located. Use it.
        [deferred resolve:cachedImageDataDict];
    }else{
        // Get json data for image asynchronously
        NSURL * url = [self getJsonUrl];
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
        
        NSLog(@"Retrieving json data from url %@", url);
        
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:retrievedJsonUrlData];
        /*
        // Get json data for image synchronously
        NSError *err = nil;
        NSData *urlData = [NSData dataWithContentsOfURL:[self getJsonUrl] options:nil error:&err];
        retrievedJsonUrlData(nil, urlData, err);
        */
    }
}

#pragma mark - Categories

-(NSMutableArray *)getCategoriesFromJson:(NSDictionary *)json
{
    NSMutableArray *categories = [@[] mutableCopy];
    for (NSString *page in json[@"query"][@"pages"]) {
        for (NSDictionary *category in json[@"query"][@"pages"][page][@"categories"]) {
            NSMutableString *categoryTitle = [category[@"title"] mutableCopy];
            // Remove "Category:" prefix from category title
            NSError *error = NULL;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^Category:" options:NSRegularExpressionCaseInsensitive error:&error];
            [regex replaceMatchesInString:categoryTitle options:0 range:NSMakeRange(0, [categoryTitle length]) withTemplate:@""];
            [categories addObject:categoryTitle];
        }
    }
    if (categories == nil) categories = [@[] mutableCopy];
    return categories;
}

#pragma mark - Description

- (NSString *)getDescriptionFromJson:(NSDictionary *)json
{
    __block NSMutableString *description = [@"" mutableCopy];
    for (NSString *page in json[@"query"][@"pages"]) {
        for (NSDictionary *revision in json[@"query"][@"pages"][page][@"revisions"]) {
            //NSMutableString *pageHTML = [category[@"*"] mutableCopy];
            descriptionParser_.xml = revision[@"parsetree"];
            descriptionParser_.done = ^(NSDictionary *descriptions){
                
                /*
                for (NSString *description in descriptions) {
                    NSLog(@"[%@] description = %@", description, descriptions[description]);
                }
                */
                
                // Show description for locale
                NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
                language = [MWI18N filterLanguage:language];
                description = ([descriptions objectForKey:language]) ? descriptions[language] : descriptions[@"en"];
            };
            [descriptionParser_ parse];
        }
    }
    if (description == nil) description = [@"" mutableCopy];
    return description;
}

#pragma mark - JSON

-(NSMutableDictionary *)getDataToCacheFromJson:(NSDictionary *)json
{
    NSMutableDictionary *dataToCache = [[NSMutableDictionary alloc] init];
    
    // Clean up the metadata so its key values pairs are dictionary key value pairs
    NSDictionary *metadata = [self getMetadataFromJson:json];
    
    NSLog(@"Image Metadata = %@", metadata);
    //NSLog(@"Camera Model = %@", metadata[@"Model"]);

    dataToCache[@"metadata"] = metadata;

    // Cache all children of imageinfo not just metadata
    // (metadata is cached separately as it gets cleaned by "getMetadataFromJson:")
    for (NSString *key in [[self pageIdNodeFromJson:json][@"imageinfo"] objectAtIndex:0]) {
        if ([key isEqualToString:@"metadata"]) continue;
        //NSLog(@"KEY in imageinfo = %@", key);
        dataToCache[key] = [[self pageIdNodeFromJson:json][@"imageinfo"] objectAtIndex:0][key];
    }

    // Cache all siblings of imageinfo
    for (NSString *key in [self pageIdNodeFromJson:json]) {
        if ([key isEqualToString:@"imageinfo"]) continue;
        //NSLog(@"KEY imageinfo sibling = %@", key);
        dataToCache[key] = [self pageIdNodeFromJson:json][key];
    }
    return dataToCache;
}

-(CGSize)getSizeFromJson:(NSDictionary *)json
{
    // Determine the height and width of the image from the json data
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
    id metadata = [self getValueForKey:@"metadata" fromJson:json];
    if (metadata && ![metadata isMemberOfClass:[NSNull class]]) {
        for (NSDictionary* pair in metadata) {
            result[pair[@"name"]] = pair[@"value"];
        }
    }
    return result;
}

#pragma mark - Caching

- (NSDictionary *)cachedDictForKey:(NSString *)key
{
    NSString *imgDataPath = [self fullCacheFilePath:key extension:@"dict"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:imgDataPath]) {
        NSData *data = [NSData dataWithContentsOfFile:imgDataPath options:nil error:nil];

        NSMutableDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];

        // Load the jpg data from the jpg file back into the dictionary's "image" entry
        NSString *jpgPath = [self fullCacheFilePath:key extension:@"jpg"];
        if ([fm fileExistsAtPath:jpgPath]) {
            NSError *err = nil;
            NSData *jpgData = [NSData dataWithContentsOfFile:jpgPath options:nil error:&err];
            if (err == nil) {
                dict[@"image"] = jpgData;
            }
        }
        return dict;
    } else {
        return nil;
    }
}

-(void)setCachePath:(NSString *)newCachePath
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:newCachePath]) {
        NSError *err;
        [fm createDirectoryAtPath:newCachePath withIntermediateDirectories:YES attributes:nil error:&err];
    }
    _cachePath = newCachePath;
}

- (NSString *)fullCacheFilePath:(NSString *)fileName extension:(NSString *)extension
{
    return [NSString stringWithFormat:@"%@%@.%@", self.cachePath, fileName, extension];
}

- (void)cacheDict:(NSMutableDictionary *)dict forKey:(NSString *)key
{
    // Dict is to be written out to file, but first take the jpg data from its "image"
    // key and write it out to a jpg file with the same name as the "dict" file but
    // a jpg extension

    // Note: rather than making a copy of dict, which contains a large amound of image
    // data in dict["image"], copy all the non-image keys. (much faster than unncessarily
    // copying all the image data)
    NSMutableDictionary *dictWithoutImageData = [[NSMutableDictionary alloc] init];
    for (NSString *key in dict) {
        if ([key isEqualToString:@"image"]) continue;
        dictWithoutImageData[key] = dict[key];
    }

    // Save dictWithoutImageData, but make its "image" key be set to the name of the image
    // rather than the actual data
    NSData *jpgData = UIImageJPEGRepresentation([UIImage imageWithData:dict[@"image"]], 0.9f);
    [jpgData writeToFile:[self fullCacheFilePath:key extension:@"jpg"] atomically:YES];
    dictWithoutImageData[@"image"] = [NSString stringWithFormat:@"%@.jpg", key];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictWithoutImageData];
    [data writeToFile:[self fullCacheFilePath:key extension:@"dict"] atomically:YES];
}

#pragma mark - Extreme panorama detection

-(BOOL)isAspectRatioOkForSize:(CGSize)size
{
    // If no ration specified then don't continue
    if (self.maxWidthHeightRatio == 0.0f) return YES;
    
    // Avoid zero division errors
    size.width += 0.00001f;
    size.height += 0.00001f;
    
    float r = size.width / size.height;
    if (r < 1.0f) r = 1.0f / r;
    // If the image is more than maxWidthHeightRatio as wide as it is tall, or more than maxWidthHeightRatio as
    // tall as it is wide, then its not ok to use because only a small part of the thumb will end up being
    // onscreen because aspect fill is being used to ensure the entire background of the login view
    //controller's view is filled with image
    return (r > self.maxWidthHeightRatio) ? NO : YES;
}

@end
