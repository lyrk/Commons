//
//  CommonsApp.m
//  Commons-iOS
//
//  Created by Brion on 1/25/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "MWI18N/MWI18N.h"

#import "CommonsApp.h"
#import "Http.h"

@implementation CommonsApp

static CommonsApp *singleton_;

+ (CommonsApp *)singleton
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{ singleton_ = [[CommonsApp alloc] init]; });
    return singleton_;
}

- (void)initializeApp
{
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    [MWI18N setLanguage:language];

    // Register default perferences with 'defaults.plist' file
    NSString *defaultsFile = [[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:defaultsFile];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    [self loadCredentials];
    [self setupData];
    [self fetchUploadRecords];
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
        if (!record.complete.boolValue) {
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
                                                andPassword:self.password
                                      withCookiePersistence:YES];
    [login done:^(MWApiResult *loginResult) {
       
       NSLog(@"login: %@", loginResult.data[@"login"][@"result"]);
       
       if (_currentUploadOp.isLoggedIn) {
           
           record.progress = @0.0f;
           
           MWPromise *upload = [_currentUploadOp uploadFile:fileName
                                               withFileData:fileData
                                                       text:[self formatDescription:record]
                                                    comment:@"Uploaded with Commons for iOS"];

           [upload progress:^(NSDictionary *dict) {
               NSLog(@"Got a progress block %@", dict);
               // Progress block
               NSNumber *bytesSent = dict[@"sent"];
               NSNumber *bytesTotal = dict[@"total"];
               record.progress = [NSNumber numberWithFloat:bytesSent.floatValue / bytesTotal.floatValue];
           }];
           
           // Completion block
           [upload done:^(MWApiResult *uploadResult) {
               NSDictionary *upload = uploadResult.data[@"upload"];
               NSDictionary *imageinfo = upload[@"imageinfo"];
               if ([upload[@"result"] isEqualToString:@"Success"]) {
                   record.title = [self cleanupTitle:upload[@"filename"]];

                   // Unfortunately we didn't get the thumbnail URL. :P
                   // Ask for it in a second request...
                   NSLog(@"fetching thumb URL after upload");
                   MWPromise *saveThumb = [record saveThumbnail];
                   [saveThumb done:^(MWApiResult *result) {
                       [deferred resolve:record];
                   }];
               } else {
                   NSLog(@"failed upload!");
                   // whaaaaaaat?
                   record.progress = @0.0f;
                   [self saveData];

                   NSError *err = nil; // fixme create a sane error object?
                   [deferred reject:err];
               }
           }];
           
           // Failure block
           [upload fail:^(NSError *error) {
               NSLog(@"failed upload!");
               record.progress = @0.0f;
               [deferred reject:error];
           }];
       } else {
           NSLog(@"not logged in");
       }
    }];
    [login fail:^(NSError *err) {
        [deferred reject:err];
    }];
    return deferred.promise;
}

- (NSString *)formatDescription:(FileUpload *)record
{
    // fixme add date? eg {{According to EXIF data|2012-11-24}}
    NSString *format = @"== {{int:filedesc}} ==\n"
                       @"{{Information|Description=%@|source={{own}}|author=[[User:%@]]}}\n" 
                       @"== {{int:license-header}} ==\n"
                       @"{{self|cc-by-sa-3.0}}\n"
                       @"\n"
                       @"{{Uploaded from Mobile|platform=iOS|version=%@}}\n";
    NSString *desc = [NSString stringWithFormat:format, record.desc, self.username, self.version];
    return desc;
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
        @"image/jpeg": @"jpg",
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

- (MWPromise *)prepareImage:(NSDictionary *)info
{
    MWDeferred *deferred = [[MWDeferred alloc] init];
    MWPromise *fetch = [self getImageData:info];
    [fetch done:^(NSData *data) {
        NSString *title = [NSString stringWithFormat:@"Testfile %li", (long)[[NSDate date] timeIntervalSince1970]];
        NSString *desc = @"temporary description text";
        
        
        FileUpload *record = [self createUploadRecord];
        record.complete = @NO;

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
- (MWPromise *)fetchImageURL:(NSURL *)url
{
    MWDeferred *deferred = [[MWDeferred alloc] init];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    void (^done)(NSURLResponse*, NSData*, NSError*) = ^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error == nil) {
            UIImage *image = [UIImage imageWithData:data];
            [deferred resolve:image];
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
 * Won't make use of caching for the image metadata, but should for the actual file.
 */
- (MWPromise *)fetchWikiImage:(NSString *)title size:(CGSize)size
{
    MWDeferred *deferred = [[MWDeferred alloc] init];
    MWApi *api = [self startApi];
    MWPromise *lookup = [api getRequest:@{
     @"action": @"query",
     @"prop": @"imageinfo",
     @"titles": [@"File:" stringByAppendingString:[self cleanupTitle:title]],
     @"iiprop": @"url",
     @"iiurlwidth": [NSString stringWithFormat:@"%f", size.width],
     @"iiurlheight": [NSString stringWithFormat:@"%f", size.height]
    }];
    [lookup done:^(MWApiResult *result) {
        NSDictionary *pages = result.data[@"query"][@"pages"];
        for (NSString *key in pages) {
            NSDictionary *page = pages[key];
            NSDictionary *imageinfo = page[@"imageinfo"][0];
            NSURL *thumbUrl = [NSURL URLWithString:imageinfo[@"thumburl"]];
            MWPromise *fetch = [self fetchImageURL:thumbUrl];
            [fetch done:^(UIImage *image) {
                [deferred resolve:image];
            }];
            [fetch fail:^(NSError *err) {
                [deferred reject:err];
            }];
        }
    }];
    [lookup fail:^(NSError *err) {
        [deferred reject:err];
    }];
    return deferred.promise;
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
    MWApi *api = [self startApi];
    MWPromise *req = [api getRequest: @{
     @"action": @"query",
     @"generator": @"allimages",
     @"gaisort": @"timestamp",
     @"gaidir": @"descending",
     @"gaiuser": self.username,
     @"gailimit": @"100",
     @"prop": @"imageinfo",
     @"iiprop": @"timestamp|url",
     @"iiurlwidth": @"640",
     @"iiurlheight": @"640"
    }];
    [req done:^(MWApiResult *result) {
        NSFetchedResultsController *records = [self fetchUploadRecords];
        for (FileUpload *oldRecord in records.fetchedObjects) {
            if (oldRecord.complete.boolValue) {
                [self deleteUploadRecord:oldRecord];
            }
        }
        records = nil;
       
        /*
         page: {
         imageinfo =     (
         {
         descriptionurl = "https://test.wikipedia.org/wiki/File:Testfile_1359577778.png";
         thumbheight = 424;
         thumburl = "https://upload.wikimedia.org/wikipedia/test/thumb/5/5d/Testfile_1359577778.png/318px-Testfile_1359577778.png";
         thumbwidth = 318;
         url = "https://upload.wikimedia.org/wikipedia/test/5/5d/Testfile_1359577778.png";
         }
         );
         imagerepository = local;
         ns = 6;
         pageid = 66296;
         title = "File:Testfile 1359577778.png";
         }
         */
        NSDictionary *pages = result.data[@"query"][@"pages"];
        for (NSString *pageId in pages) {
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

@end
