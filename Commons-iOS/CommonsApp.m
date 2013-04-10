//
//  CommonsApp.m
//  Commons-iOS
//
//  Created by Brion on 1/25/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import <sys/utsname.h>
#import "MWI18N/MWI18N.h"

#import "CommonsApp.h"

@implementation CommonsApp

static CommonsApp *singleton_;

+ (CommonsApp *)singleton
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{ singleton_ = [[CommonsApp alloc] init]; });
    return singleton_;
}

- (NSString *)machineName
{
    struct utsname systemInfo;
    uname(&systemInfo);

    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

- (MWEventLogging *)setupLog
{
    NSURL *endPoint = [NSURL URLWithString:@"https://bits.wikimedia.org/event.gif"];
    return [[MWEventLogging alloc] initWithEndpointURL:endPoint];
}

- (void)initializeApp
{
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    [MWI18N setLanguage:language];

    self.eventLog = [self setupLog];
    [self.eventLog setSchema:@"MobileAppLoginAttempts" meta:@{
        @"revision": @5257721
    }];
    [self.eventLog setSchema:@"MobileAppUploadAttempts" meta:@{
        @"revision": @5334329
    }];
    [self updateLogOptions];
    
    self.thumbFetcher = [[ThumbFetcher alloc] init];

    // Register default perferences with 'defaults.plist' file
    NSString *defaultsFile = [[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:defaultsFile];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    [self loadCredentials];
    [self setupData];
    if ([self.username length] != 0) { // @todo handle lack of upload records
        [self fetchUploadRecords];
    }
}

- (void)updateLogOptions
{
    if (self.debugMode) {
        self.eventLog.host = @"test.wikipedia.org";
        self.eventLog.wiki = @"testwiki";
    } else {
        self.eventLog.host = @"commons.wikimedia.org";
        self.eventLog.wiki = @"commonswiki";
    }
}

- (NSString *)version
{
    return NSBundle.mainBundle.infoDictionary[(NSString*)kCFBundleVersionKey];
}

- (BOOL)debugMode {
    
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"DebugMode"];
}

- (void)setDebugMode:(BOOL)value {
    
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:@"DebugMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self updateLogOptions];
}

- (void)loadCredentials
{
    self.username = [self getKeychainValueForEntry:@"org.wikimedia.username"];
    self.password = [self getKeychainValueForEntry:@"org.wikimedia.password"];
}

- (void)saveCredentials
{
    [self setKeychainValue:self.username forEntry:@"org.wikimedia.username"];
    [self setKeychainValue:self.password forEntry:@"org.wikimedia.password"];
}

- (BOOL)processLaunchURL:(NSURL *)url
{
    NSLog(@"Launched with URL: %@", url);
    NSString *path = [self realPath:url.path];
    NSString *inbox = [[self realPath:[self documentRootPath]] stringByAppendingString:@"/Inbox/"];
    
    if ([[path substringToIndex:[inbox length]] isEqualToString:inbox]) {
        NSString *fileName = [path lastPathComponent];
        NSLog(@"loading %@ from another app...", fileName);

        // Read into memory...
        NSData *data = [NSData dataWithContentsOfFile:path];

        // Delete the source file, we're done with it.
        NSFileManager *fm = [NSFileManager defaultManager];
        __autoreleasing NSError *error;
        [fm removeItemAtPath:path error:&error];

        // Store it!
        [self prepareFile:fileName data:data];

        return YES;
    } else {
        NSLog(@"Didn't recognize file path %@ - not in inbox %@", path, inbox);
        return NO;
    }
}

- (NSString *)realPath:(NSString *)path
{
    // fixme are we leaking the UTF8String?
    const char *bits = realpath([path UTF8String], NULL);
    NSString *ret = [NSString stringWithUTF8String:bits];
    free((void *)bits);
    return ret;
}

- (BOOL)setKeychainValue:(NSString *)value forEntry:(NSString *)entry
{
    NSData *encodedName = [entry dataUsingEncoding:NSUTF8StringEncoding];
    NSData *valueData = [value dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dict = @{
    (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
    (__bridge id)kSecAttrService: [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"],
    (__bridge id)kSecAttrGeneric: encodedName,
    (__bridge id)kSecAttrAccount: encodedName,
    (__bridge id)kSecValueData: valueData,
    (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleWhenUnlocked,
    };
    
    // Create the keychain item, if it doesn't yet exist...
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)dict, NULL);
    if (status == errSecSuccess) {
        return YES;
    } else if (status == errSecDuplicateItem) {
        // Exists! Pass through to update.
        return [self updateKeychainValue:value forEntry:entry];
    } else {
        NSLog(@"Keychain: Something exploded; SecItemAdd returned %i", (int)status);
        return NO;
    }
}

- (BOOL)updateKeychainValue:(NSString *)value forEntry:(NSString *)entry
{
    NSData *encodedName = [entry dataUsingEncoding:NSUTF8StringEncoding];
    NSData *valueData = [value dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dict = @{
    (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
    (__bridge id)kSecAttrService: [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"],
    (__bridge id)kSecAttrGeneric: encodedName,
    (__bridge id)kSecAttrAccount: encodedName
    };
    NSDictionary *dataDict = @{
    (__bridge id)kSecValueData: valueData
    };
    
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)dict, (__bridge CFDictionaryRef)dataDict);
    if (status == errSecSuccess) {
        return YES;
    } else {
        NSLog(@"Keychain: SecItemUpdate returned %i", (int)status);
        return NO;
    }
}

- (NSString *)getKeychainValueForEntry:(NSString *)entry
{
    NSData *encodedName = [entry dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dict = @{
    (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
    (__bridge id)kSecAttrService: [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"],
    (__bridge id)kSecAttrGeneric: encodedName,
    (__bridge id)kSecAttrAccount: encodedName,
    (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
    (__bridge id)kSecReturnData: (__bridge id)kCFBooleanTrue
    };
    
    // Fetch username and password from keychain
    CFTypeRef found = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)dict, &found);
    if (status == noErr) {
        NSData *result = (__bridge_transfer NSData *)found;
        return [[NSString alloc] initWithData: result encoding:NSUTF8StringEncoding];
    } else {
        NSLog(@"Keychain: SecItemCopyMatching returned %i", (int)status);
        return @"";
    }
}

- (NSString *)documentRootPath
{
    NSArray* documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentRootPath = [documentPaths objectAtIndex:0];
    return documentRootPath;
}

- (NSString *)filePath:(NSString *)fileName
{
    return [[self documentRootPath] stringByAppendingFormat:@"/queued/%@", fileName];
}

- (NSString *)thumbPath:(NSString *)fileName
{
    return [[self documentRootPath] stringByAppendingFormat:@"/thumbs/%@", fileName];
}

- (NSString *)thumbPath2x:(NSString *)fileName
{
    return [[[self thumbPath:fileName] stringByDeletingPathExtension] stringByAppendingString:@"@2x.jpg"];
}

- (NSString *)uniqueFilenameWithExtension:(NSString *)extension;
{
    // fixme include some nice randoms
    long date = [[NSDate date] timeIntervalSince1970];
    int randomNumber = arc4random();
    NSString *filename = [NSString stringWithFormat:@"%li-%i.%@", date, randomNumber, extension];
    return filename;
}

- (void)ensureDirectory:(NSString *)dir
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:dir]) {
        NSError *err;
        [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&err];
    }
}

- (void)setupData
{
    NSString *root = [self documentRootPath];

    // Create queued file & thumb storage directories
    [self ensureDirectory: [root stringByAppendingString:@"/queued"]];
    [self ensureDirectory: [root stringByAppendingString:@"/thumbs"]];

    // Initialize CoreData
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    
    NSString* dataPath = [root stringByAppendingString:@"/uploads.sqlite"];
    NSLog(@"data path: %@", dataPath);
    NSURL *url = [NSURL fileURLWithPath:dataPath];
    
    NSError *error;
    if ([persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]) {
        NSLog(@"Created persistent store.");
    } else {
        NSLog(@"Error creating persistent store coordinator: %@", error.localizedFailureReason);
    }
    self.context = [[NSManagedObjectContext alloc] init];
    self.context.persistentStoreCoordinator = persistentStoreCoordinator;
}

- (void)saveData
{
    NSError *error;
    BOOL success = [self.context save:&error];
    if (success) {
        NSLog(@"Saved database.");
    } else {
        NSLog(@"Error saving database: %@", error.localizedFailureReason);
    }
}

- (FileUpload *)createUploadRecord
{
    return [NSEntityDescription insertNewObjectForEntityForName:@"FileUpload" inManagedObjectContext:self.context];
}

- (NSFetchedResultsController *)fetchUploadRecords
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"created" ascending:NO selector:nil];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"FileUpload"
                                              inManagedObjectContext:self.context];
    [fetchRequest setEntity:entity];

    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                 managedObjectContext:self.context
                                                                                   sectionNameKeyPath:nil
                                                                                            cacheName:nil];
    NSError *error = nil;
    [controller performFetch:&error];

    return controller;
}

- (FileUpload *)firstUploadRecord
{
    NSFetchedResultsController *controller = [self fetchUploadRecords];
    NSArray *objs = controller.fetchedObjects;
    for (FileUpload *record in objs) {
        if (record.isReadyForUpload) {
            return record;
        }
    }
    return nil;
}

- (MWApi *)startApi
{
    NSURL *url = [NSURL URLWithString:[[self wikiURLBase] stringByAppendingString:@"/w/api.php"]];
    return [[MWApi alloc] initWithApiUrl:url];;
}

- (NSString *)wikiURLBase
{
    if (self.debugMode) {
        return @"https://test.wikipedia.org";
    } else {
        return @"https://commons.wikimedia.org";
    }
}

- (NSURL *)URLForWikiPage:(NSString *)title
{
    NSString *urlStr = [NSString stringWithFormat:@"%@/wiki/%@",
                                                 [self wikiURLBase],
                                                 [self encodeWikiTitle:title]];
    return [NSURL URLWithString:urlStr];
}

- (NSString *)encodeWikiTitle:(NSString *)title
{
    // note: MediaWiki de-escapes a couple of things for its canonical URLs.
    return [[title stringByReplacingOccurrencesOfString:@" " withString:@"_"]
            stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (MWPromise *)beginUpload:(FileUpload *)record
{
    NSString *fileName = [self filenameForTitle:record.title type:record.fileType];
    NSString *filePath = [self filePath:record.localFile];
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    
    _currentUploadOp = [self startApi];
    
    MWDeferred *deferred = [[MWDeferred alloc] init];
    MWPromise *login = [_currentUploadOp loginWithUsername:self.username
                                                andPassword:self.password];
    [login done:^(NSDictionary *loginResult) {
       
       if (_currentUploadOp.isLoggedIn) {
           
           record.progress = @0.0f;
           
           MWPromise *upload = [_currentUploadOp uploadFile:fileName
                                               withFileData:fileData
                                                       text:[self formatDescription:record]
                                                    comment:@"Uploaded with Commons for iOS"];

           [upload progress:^(NSDictionary *dict) {
               // Progress block
               NSNumber *bytesSent = dict[@"sent"];
               NSNumber *bytesTotal = dict[@"total"];
               record.progress = [NSNumber numberWithFloat:bytesSent.floatValue / bytesTotal.floatValue];
           }];
           
           // Completion block
           [upload done:^(NSDictionary *uploadResult) {
               NSDictionary *upload = uploadResult[@"upload"];
               if ([upload[@"result"] isEqualToString:@"Success"]) {
                   record.title = [self cleanupTitle:upload[@"filename"]];
                   record.complete = @YES;
                   record.progress = @1.0f;
                   [self saveData];

                   [self log:@"MobileAppUploadAttempts" event:@{
                        @"source": record.source,
                        @"filename": fileName,
                        @"result": @"success",
                        @"multiple": @NO
                    }];
                   
                   [deferred resolve:record];
               } else {
                   [self log:@"MobileAppUploadAttempts" event:@{
                        @"source": record.source,
                        @"filename": fileName,
                        @"result": upload[@"result"],
                        @"multiple": @NO
                    }];

                   // whaaaaaaat?
                   record.progress = @0.0f;
                   [self saveData];

                   NSError *err = nil; // fixme create a sane error object?
                   [deferred reject:err];
               }
           }];
           
           // Failure block
           [upload fail:^(NSError *error) {
               [self.eventLog log:@"MobileAppUploadAttempts" event:@{
                    @"source": record.source,
                    @"filename": fileName,
                    @"result": MW_ERROR_CODE(error),
                    @"multiple": @NO
                }];
               record.progress = @0.0f;
               [deferred reject:error];
           }];
       } else {
           [self.eventLog log:@"MobileAppLoginAttempts" event:@{
                @"source": @"launcher", // fixme?
                @"result": loginResult[@"login"][@"result"] // and/or data[error][code]?
            }];
       }
    }];
    [login fail:^(NSError *err) {
        [self log:@"MobileAppLoginAttempts" event:@{
            @"source": @"launcher", // fixme?
            @"result": MW_ERROR_CODE(err)
        }];
        [deferred reject:err];
    }];
    return deferred.promise;
}

- (NSString *)formatDescription:(FileUpload *)record
{
    NSString *format = @"== {{int:filedesc}} ==\n"
                       @"{{Information|Description=%@|source={{own}}|author=[[User:%@]]|date=%@}}\n"
                       @"== {{int:license-header}} ==\n"
                       @"{{self|cc-by-sa-3.0}}\n"
                       @"\n"
                       @"{{Uploaded from Mobile|platform=iOS|version=%@}}\n"
                       @"{{subst:unc}}";
    NSString *desc = [NSString stringWithFormat:format, record.desc, self.username, [self formatDescriptionDate:record], self.version];
    return desc;
}

- (NSString *)formatDescriptionDate:(FileUpload *)record
{
    NSString *path = [self filePath:record.localFile];
    NSURL *url = [NSURL fileURLWithPath:path];
    NSDate *date = [self extractExifDate:url];
    if (date) {
        return [NSString stringWithFormat:@"{{According to EXIF data|%@}}", [self formatDate:date]];
    } else {
        date = [NSDate date];
        return [NSString stringWithFormat:@"{{Upload date|%@}}", [self formatDate:date]];
    }
    // fixme add date? eg {{According to EXIF data|2012-11-24}}
}

- (NSString *)formatDate:(NSDate *)date
{
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date];
    return [NSString stringWithFormat:@"%04d-%02d-%02d", components.year, components.month, components.day];
}

- (NSDate *)extractExifDate:(NSURL *)url
{
    // CGImageProperties.h.
    // kCGImagePropertyExifDictionary
    // kCGImagePropertyExifDateTimeOriginal
    CGImageSourceRef src = CGImageSourceCreateWithURL((__bridge CFURLRef)url, nil);
    NSDictionary *dict = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(src, 0, nil);
    CFRelease(src);
    
    NSString *dateStr = dict[(__bridge NSString *)kCGImagePropertyExifDictionary][(__bridge NSString *)kCGImagePropertyExifDateTimeOriginal];
    if (dateStr) {
        return [self decodeExifDate:dateStr];
    } else {
        return nil;
    }
}

- (void)cancelCurrentUpload {
    
    NSLog(@"Canceling current upload");
    
    // Stop upload
    [_currentUploadOp cancelCurrentRequest];
    
    // Reset progress on the upload
    [[self firstUploadRecord] setProgress:[NSNumber numberWithFloat:0.0f]];
    [self saveData];
}

- (NSString *)filenameForTitle:(NSString *)title type:(NSString *)fileType
{
    NSString *extension = [self extensionForType:fileType];
    
    // fixme strip chars etc
    return [[title stringByAppendingString:@"."] stringByAppendingString:extension];
}
            
- (NSString *)extensionForType:(NSString *)fileType
{
    NSDictionary *types = @{
        @"image/jpeg": @"jpeg", // chose .jpeg to minimize conflicts for now since most default to .jpg
        @"image/png": @"png",
        @"image/gif": @"gif",
        @"image/tiff": @"tif",
        @"image/svg+xml": @"svg",
        @"application/pdf": @"pdf"
    };
    NSString *extension = types[fileType];
    if (extension == nil) {
        NSLog(@"EXPLODING KABOOOOOOOOM unrecognized type %@", fileType);
    }
    return extension;
}

- (NSString *)typeForExtension:(NSString *)ext
{
    NSDictionary *map = @{
        @"jpg": @"image/jpeg",
        @"jpeg": @"image/jpeg",
        @"png": @"image/png",
        @"gif": @"image/gif",
        @"tif": @"image/tiff",
        @"tiff": @"image/tiff",
        @"svg": @"image/svg+xml",
        @"pdf": @"application/pdf"
    };
    NSString *type = map[[ext lowercaseString]];
    if (type != nil) {
        return type;
    } else {
        NSLog(@"Unrecognized file extension %@", ext);
        return @"application/octet-stream";
    }
}

- (MWPromise *)prepareImage:(NSDictionary *)info from:(NSString *)source
{
    MWDeferred *deferred = [[MWDeferred alloc] init];
    MWPromise *fetch = [self getImageData:info];
    [fetch done:^(NSData *data) {
        NSString *title = @""; // require user to fill them out
        NSString *desc = @""; // require user to fill them out
        
        
        FileUpload *record = [self createUploadRecord];
        record.complete = @NO;
        record.source = source;

        record.created = [NSDate date];
        record.title = title;
        record.desc = desc;
        
        record.fileType = [self getImageType:info];
        record.fileSize = [NSNumber numberWithInteger:[data length]];
        record.progress = @0.0f;
        
        // save local file
        record.localFile = [self saveFile: data forType:record.fileType];

        [self saveData];
        [deferred resolve:record];
    }];
    [fetch fail:^(NSError *err) {
        [deferred reject:err];
    }];
    return [deferred promise];
}

- (void)prepareFile:(NSString *)fileName data:(NSData *)data
{
    NSString *extension = [fileName pathExtension];
    NSString *basename = [fileName substringToIndex:(fileName.length - extension.length - 1)];
    
    FileUpload *record = [self createUploadRecord];
    record.complete = @NO;
    record.source = @"external";
    
    record.created = [NSDate date];
    record.title = basename;
    record.desc = @"imported file";
    
    record.fileType = [self typeForExtension:extension];
    record.fileSize = [NSNumber numberWithInteger:[data length]];
    record.progress = @0.0f;
    
    // save local file
    record.localFile = [self saveFile:data forType:record.fileType];
    [self saveData];
}

- (MWPromise *)loadImage:(NSString *)fileName fileType:(NSString *)fileType
{
    MWDeferred *deferred = [[MWDeferred alloc] init];
    if ([fileType isEqualToString:@"image/svg+xml"]) {
        MWPromise *svg = [self loadSVGImage:fileName];
        [svg done:^(UIImage *image) {
            [deferred resolve:image];
        }];
        [svg fail:^(NSError *err) {
            [deferred reject:err];
        }];
    } else if ([fileType isEqualToString:@"application/pdf"]) {
        MWPromise *pdf = [self loadPDFImage:fileName];
        [pdf done:^(UIImage *image) {
            [deferred resolve:image];
        }];
        [pdf fail:^(NSError *err) {
            [deferred reject:err];
        }];
    } else {
        // dispatch to the event loop
        [NSOperationQueue.mainQueue addOperationWithBlock:^() {
            // fixme can we background decoding?
            UIImage *image = [UIImage imageWithContentsOfFile:[self filePath:fileName]];
            [deferred resolve:image];
        }];
    }
    return deferred.promise;
}

- (MWPromise *)loadSVGImage:(NSString *)fileName
{
    MWDeferred *deferred = [[MWDeferred alloc] init];
    
    // dispatch to the event loop
    [NSOperationQueue.mainQueue addOperationWithBlock:^() {
        // fixme implement thumbnailing
        UIImage *image = [UIImage imageNamed:@"fileicon-svg.png"];
        [deferred resolve:image];
    }];
    
    return deferred.promise;
}

- (MWPromise *)loadPDFImage:(NSString *)fileName
{
    MWDeferred *deferred = [[MWDeferred alloc] init];

    // dispatch to the event loop
    [NSOperationQueue.mainQueue addOperationWithBlock:^() {
        // fixme implement thumbnailing
        UIImage *image = [UIImage imageNamed:@"fileicon-pdf.png"];
        [deferred resolve:image];
    }];

    return deferred.promise;
}


/**
 * Will make use of NSURL's default caching handlers
 */
- (MWPromise *)fetchDataURL:(NSURL *)url
{
    MWDeferred *deferred = [[MWDeferred alloc] init];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    void (^done)(NSURLResponse*, NSData*, NSError*) = ^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error == nil) {
            [deferred resolve:data];
        } else {
            [deferred reject:error];
        }
    };
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:done];
    return deferred.promise;
}

/**
 * Will make use of NSURL's default caching handlers
 */
- (MWPromise *)fetchImageURL:(NSURL *)url
{
    MWDeferred *deferred = [[MWDeferred alloc] init];
    MWPromise *fetch = [self fetchDataURL:url];
    [fetch done:^(NSData *data) {
        UIImage *image = [UIImage imageWithData:data scale:1.0];
        [deferred resolve:image];
    }];
    [fetch fail:^(NSError *err) {
        [deferred reject:err];
    }];
    return deferred.promise;
}

/**
 * Won't make use of caching for the image metadata, but should for the actual file.
 */
- (MWPromise *)fetchWikiImage:(NSString *)title size:(CGSize)size
{
    return [self.thumbFetcher fetchThumbnail:title size:size];
}

- (void)deleteUploadRecord:(FileUpload *)record
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    if (record.localFile) {
        [fm removeItemAtPath: [self filePath:record.localFile] error:&error];
    }
    [self.context deleteObject:record];
    [self saveData];
}

- (MWPromise *)getImageData:(NSDictionary *)info
{
    MWDeferred *deferred = [[MWDeferred alloc] init];
    NSURL *url = info[UIImagePickerControllerReferenceURL];
    if (url != nil) {
        // We picked something from the photo library; fetch its original data.
        MWPromise *getAsset = [self getAssetImageData:url];
        [getAsset pipe:deferred];
    } else {
        // Freshly-taken photo. Add it to the camera roll and fetch it back;
        // this not only is polite (keep your photos locally) but it conveniently
        // adds the EXIF metadata in, which UIImageJPEGRepresentation doesn't do.
        MWPromise *save = [self saveImageData:info];
        [save done:^(NSURL *savedUrl) {
            MWPromise *getData = [self getAssetImageData:savedUrl];
            [getData pipe:deferred];
        }];
        [save fail:^(NSError *err) {
            [deferred reject:err];
        }];
    }
    return deferred.promise;
}

- (NSString *)getImageType:(NSDictionary *)info
{
    NSURL *url = info[UIImagePickerControllerReferenceURL];
    if (url != nil) {
        return [self typeForExtension:[url pathExtension]];
    } else {
        // Freshly taken photo, we'll go craaaazy
        return @"image/jpeg";
    }
}

- (MWPromise *)saveImageData:(NSDictionary *)info
{
    MWDeferred *deferred = [[MWDeferred alloc] init];
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    NSDictionary *metadata = info[UIImagePickerControllerMediaMetadata];
    ALAssetsLibrary *assetLibrary=[[ALAssetsLibrary alloc] init];
    [assetLibrary writeImageToSavedPhotosAlbum:image.CGImage
                                      metadata:metadata
                               completionBlock:^(NSURL *assetURL, NSError *error) {
                                   if (error == nil) {
                                       [deferred resolve:assetURL];
                                   } else {
                                       [deferred reject:assetURL];
                                   }
                               }];
    return deferred.promise;
}

- (MWPromise *)getAssetImageData:(NSURL *)url
{
    MWDeferred *deferred = [[MWDeferred alloc] init];

    void (^complete)(ALAsset *) = ^(ALAsset *asset) {
        ALAssetRepresentation *rep = [asset defaultRepresentation];
        Byte *buffer = (Byte*)malloc(rep.size);
        NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
        NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
        [deferred resolve:data];
    };

    void (^fail)(NSError*) = ^(NSError *err) {
        [deferred reject:err];
    };

    ALAssetsLibrary *assetLibrary=[[ALAssetsLibrary alloc] init];
    [assetLibrary assetForURL:url
                  resultBlock:complete
                 failureBlock:fail];

    return [deferred promise];
}

- (NSString *)saveFile:(NSData *)data forType:(NSString *)fileType
{
    NSString *fileName = [self uniqueFilenameWithExtension:@"jpg"];
    NSString *filePath = [self filePath:fileName];
    [data writeToFile:filePath atomically:YES];
    return fileName;
}

- (MWPromise *)refreshHistory
{
    MWDeferred *deferred = [[MWDeferred alloc] init];

    // Find the latest entry
    // fixme do this more efficiently
    NSDate *latest = nil;
    NSFetchedResultsController *records = [self fetchUploadRecords];
    for (FileUpload *oldRecord in records.fetchedObjects) {
        if (oldRecord.complete.boolValue) {
            if (latest == nil || [latest compare:oldRecord.created] == NSOrderedAscending) {
                latest = oldRecord.created;
            }
        }
    }

    // Ask the API for any new changes
    MWApi *api = [self startApi];
    NSMutableDictionary *params = [@{
                                    @"action": @"query",
                                    @"list": @"logevents",
                                    @"leaction": @"upload/upload",
                                    @"leprop": @"title|timestamp",
                                    @"leuser": self.username,
                                    @"lelimit": @"500",
                                    @"ledir": @"newer"
                                    } mutableCopy];
    if (latest) {
        params[@"lestart"] = [api formatTimestamp:latest];
    }

    MWPromise *req = [api getRequest:params];
    [req done:^(NSDictionary *result) {
       
        /*
         {
             "query": {
                 "logevents": [
                     {
                     "ns": 6,
                     "title": "File:Test image xyz.jpg",
                     "timestamp": "2013-03-01T21:10:21Z"
                     },
                     ...
                ]
             }
         }
         */
        for (NSDictionary *logevent in result[@"query"][@"logevents"]) {
            NSLog(@"%@", logevent);
            /*
            (^() {
                NSDictionary *page = pages[pageId];
                NSDictionary *imageinfo = page[@"imageinfo"][0];
                NSLog(@"page: %@", page);

                FileUpload *record = [self createUploadRecord];
                record.complete = @YES;

                record.title = [self cleanupTitle:page[@"title"]];
                record.progress = @1.0f;
                record.created = [self decodeDate:imageinfo[@"timestamp"]];

               record.thumbnailURL = imageinfo[@"thumburl"];
               
                [self saveData];
            })();
             */
            
            NSString *title = [self cleanupTitle:logevent[@"title"]];
            BOOL skip = NO;

            // fixme do this more efficiently
            // check for dupes
            for (FileUpload *oldRecord in records.fetchedObjects) {
                if (oldRecord.complete.boolValue) {
                    if ([oldRecord.title isEqualToString:title]) {
                        skip = YES;
                        break;
                    }
                }
            }
            if (skip) {
                NSLog(@"Skipping known record for %@", title);
                continue;
            }
            
            FileUpload *record = [self createUploadRecord];
            record.complete = @YES;
            
            record.title = title;
            record.progress = @1.0f;
            record.created = [self decodeDate:logevent[@"timestamp"]];
            
            //record.thumbnailURL = imageinfo[@"thumburl"];
            
            [self saveData];
        }
        [deferred resolve:nil];
    }];
    [req fail:^(NSError *error) {
        NSLog(@"Failed to refresh history: %@", [error localizedDescription]);
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Refresh failed!"
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"Dismiss"
                                                  otherButtonTitles:nil];
        [alertView show];
        [deferred reject:error];
    }];
    return [deferred promise];
}

- (NSString *)prettyDate:(NSDate *)date
{
    NSDate *now = [NSDate date];
    NSTimeInterval interval = [now timeIntervalSinceDate:date];
    if (interval < 3600.0) {
        double minutes = interval / 60.0;
        return [MWMessage forKey:@"reltime-minutes" param:[NSString stringWithFormat:@"%0.0f", minutes]].text;
    } else if (interval < 86400.0) {
        double hours = interval / 3600.0;
        return [MWMessage forKey:@"reltime-hours" param:[NSString stringWithFormat:@"%0.0f", hours]].text;
    } else {
        double days = interval / 86400.0;
        return [MWMessage forKey:@"reltime-days" param:[NSString stringWithFormat:@"%0.0f", days]].text;
    }
}

- (NSDate *)decodeDate:(NSString *)str
{
    int year, month, day, h, m, s;

    // 2012-08-27T20:08:10Z
    sscanf([str UTF8String], "%d-%d-%dT%d:%d:%dZ", &year, &month, &day, &h, &m, &s);

    NSDateComponents *parts = [[NSDateComponents alloc] init];
    parts.year = year;
    parts.month = month;
    parts.day = day;
    parts.hour = h;
    parts.minute = m;
    parts.second = s;
    parts.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];

    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];

    NSDate *date = [gregorian dateFromComponents:parts];

    return date;
}

- (NSDate *)decodeExifDate:(NSString *)str
{
    int year, month, day, h, m, s;
    
    // 2013:02:26 16:34:32
    sscanf([str UTF8String], "%d:%d:%d %d:%d:%d", &year, &month, &day, &h, &m, &s);
    
    NSDateComponents *parts = [[NSDateComponents alloc] init];
    parts.year = year;
    parts.month = month;
    parts.day = day;
    parts.hour = h;
    parts.minute = m;
    parts.second = s;
    parts.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"]; // likely to be wildly wrong, but eh
    
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDate *date = [gregorian dateFromComponents:parts];
    
    return date;
}

- (NSString *)cleanupTitle:(NSString *)title
{
    // First, strip a 'File:' namespace prefix if present
    NSArray *parts = [title componentsSeparatedByString:@":"];
    NSString *main;
    main = parts[parts.count - 1];
    if (parts.count > 1) {
        main = parts[1];
    }

    // Convert underscores to spaces
    NSString *display = [main stringByReplacingOccurrencesOfString:@"_" withString:@" "];

    return display;
}

/**
 * Record a log event and send to upstream tracking,
 * filling out some common fields.
 */
- (void)log:(NSString *)schemaName event:(NSDictionary *)event
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:event];
    UIDevice *device = [UIDevice currentDevice];
    if (dict[@"username"] == nil) {
        dict[@"username"] = self.username;
    }
    dict[@"device"] = self.machineName;
    dict[@"platform"] = [@"iOS/" stringByAppendingString:device.systemVersion];
    dict[@"appversion"] = [@"iOS/" stringByAppendingString:self.version];

    [self.eventLog log:schemaName event:dict];
}

@end
