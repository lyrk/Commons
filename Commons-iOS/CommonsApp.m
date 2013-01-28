//
//  CommonsApp.m
//  Commons-iOS
//
//  Created by Brion on 1/25/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

#import "CommonsApp.h"
#import "mwapi/MWApi.h"

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
    [self loadCredentials];
    [self setupData];
    [self fetchUploadRecords];
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
    NSString *filename = [NSString stringWithFormat:@"%li.%@", (long)[[NSDate date] timeIntervalSince1970], extension];
    return filename;
}

- (UIImage *)loadThumbnail:(NSString *)fileName;
{
    return [[UIImage alloc] initWithContentsOfFile:[self thumbPath:fileName]];
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
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"created" ascending:YES selector:nil];
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
    if (objs.count) {
        return objs[0];
    } else {
        return nil;
    }
}

- (void)beginUpload:(FileUpload *)record completion:(void(^)())completionBlock;
{
    NSString *filePath = [self filePath:record.localFile];
    NSData *jpeg = [NSData dataWithContentsOfFile:filePath];
    
    NSURL *url = [NSURL URLWithString:@"https://test2.wikipedia.org/w/api.php"];
    MWApi *mwapi = [[MWApi alloc] initWithApiUrl:url];
    
    // Run an indeterminate activity indicator during login validation...
    //[self.activityIndicator startAnimating];
    [mwapi loginWithUsername:self.username andPassword:self.password withCookiePersistence:YES onCompletion:^(MWApiResult *loginResult) {
        NSLog(@"login: %@", loginResult.data[@"login"][@"result"]);
        //[self.activityIndicator stopAnimating];
        if (mwapi.isLoggedIn) {
            record.progress = @0.0f;
            void (^progress)(NSInteger, NSInteger) = ^(NSInteger bytesSent, NSInteger bytesTotal) {
                record.progress = [NSNumber numberWithFloat:(float)bytesSent / (float)bytesTotal];
            };
            void (^complete)(MWApiResult *) = ^(MWApiResult *uploadResult) {
                // @fixme delete the data
                NSLog(@"upload: %@", uploadResult.data);
                if (completionBlock != nil) {
                    [self deleteUploadRecord:record];
                    completionBlock();
                }
            };
            [mwapi uploadFile:record.title
                 withFileData:jpeg
                         text:record.desc
                      comment:@"Uploaded with Commons for iOS"
                 onCompletion:complete
                   onProgress:progress];
        } else {
            NSLog(@"not logged in");
        }
    }];
}

- (void)prepareImage:(NSDictionary *)info onCompletion:(void(^)())completionBlock
{
    void (^done)() = [completionBlock copy];
    [self getImageData:info onCompletion:^(NSData *data) {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        
        NSString *filename = [NSString stringWithFormat:@"Testfile %li.jpg", (long)[[NSDate date] timeIntervalSince1970]];
        NSString *desc = @"temporary description text";
        
        
        FileUpload *record = [self createUploadRecord];
        
        record.created = [NSDate date];
        record.title = filename;
        record.desc = desc;
        
        record.fileType = @"image/jpeg";
        record.fileSize = [NSNumber numberWithInteger:[data length]];
        record.progress = @0.0f;
        
        // save local file
        record.localFile = [self saveFile: data forType:record.fileType];
        
        // FIXME -- save only asset URL
        //record.assetUrl = @"";

        // save thumbnail
        record.thumbnailFile = [self saveThumbnail:image];

        [self saveData];
        
        if (done != nil) {
            done();
        }
    }];
}

- (void)deleteUploadRecord:(FileUpload *)record
{
    if (record.localFile) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *error;
        [fm removeItemAtPath: [self filePath:record.localFile] error:&error];
        [fm removeItemAtPath: [self thumbPath:record.thumbnailFile] error:&error];
        [fm removeItemAtPath: [self thumbPath2x:record.thumbnailFile] error:&error];
    }
    [self.context deleteObject:record];
    [self saveData];
}

- (void)getImageData:(NSDictionary *)info onCompletion:(void (^)(NSData *))completionBlock
{
    void (^done)(NSData *) = [completionBlock copy];
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    NSURL *url = info[UIImagePickerControllerReferenceURL];
    if (url != nil) {
        [self getAssetImageData: url onCompletion:completionBlock];
    } else {
        NSData *jpeg = UIImageJPEGRepresentation(image, 0.9);
        // how to dispatch?
        if (done != nil) {
            done(jpeg);
        }
    }
}

- (void)getAssetImageData:(NSURL *)url onCompletion:(void (^)(NSData *))completionBlock
{
    __block void (^done)(NSData *) = [completionBlock copy];

    void (^complete)(ALAsset *) = ^(ALAsset *asset) {
        ALAssetRepresentation *rep = [asset defaultRepresentation];
        Byte *buffer = (Byte*)malloc(rep.size);
        NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
        NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
        done(data);
        done = nil;
    };

    void (^fail)(NSError*) = ^(NSError *err) {
        NSLog(@"Error: %@",[err localizedDescription]);
        done(nil);
        done = nil;
    };
    ALAssetsLibrary *assetLibrary=[[ALAssetsLibrary alloc] init];
    [assetLibrary assetForURL:url
                  resultBlock:complete
                 failureBlock:fail];
}

- (NSString *)saveFile:(NSData *)data forType:(NSString *)fileType
{
    NSString *fileName = [self uniqueFilenameWithExtension:@"jpg"];
    NSString *filePath = [self filePath:fileName];
    [data writeToFile:filePath atomically:YES];
    return fileName;
}

- (NSString *)saveThumbnail:(UIImage *)image
{
    // hack: do actual thumbnailing
    NSString *thumbName = [self uniqueFilenameWithExtension:@"jpg"];
    [self saveRawThumbnail:image withName:thumbName retina:NO];
    [self saveRawThumbnail:image withName:thumbName retina:YES];

    return thumbName;
}

- (void)saveRawThumbnail:(UIImage *)image withName:(NSString *)thumbName retina:(BOOL)isRetina
{
    NSInteger size;
    NSString *thumbPath;
    if (isRetina) {
        size = 128;
        thumbPath = [self thumbPath2x:thumbName];
    } else {
        size = 64;
        thumbPath = [self thumbPath:thumbName];
    }
    UIImage *thumb = [self makeThumbnail:image size:size];
    NSData *data = UIImageJPEGRepresentation(thumb, 0.7);

    [data writeToFile:thumbPath atomically:YES];
}

- (UIImage *)makeThumbnail:(UIImage *)image size:(NSInteger)size
{
    CGSize newSize = CGSizeMake((float)size, (float)size);

    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

@end
