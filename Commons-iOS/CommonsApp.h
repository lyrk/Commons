//
//  CommonsApp.h
//  Commons-iOS
//
//  Created by Brion on 1/25/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FileUpload.h"

@interface CommonsApp : NSObject

@property (strong, nonatomic) UIWindow *window;
@property (copy, nonatomic) NSString *username;
@property (copy, nonatomic) NSString *password;
@property (strong, nonatomic) UIImage *image; // temp
@property (strong, nonatomic) NSManagedObjectContext *context;

+ (CommonsApp *)singleton;

- (void)initializeApp;
- (void)loadCredentials;
- (void)saveCredentials;

- (NSString *)documentRootPath;
- (NSString *)filePath:(NSString *)fileName;
- (NSString *)thumbPath:(NSString *)fileName;
- (NSString *)uniqueFilenameWithExtension:(NSString *)extension;
- (UIImage *)loadThumbnail:(NSString *)fileName;

- (void)saveData;
- (NSFetchedResultsController *)fetchUploadRecords;
- (FileUpload *)createUploadRecord;
- (FileUpload *)firstUploadRecord;
- (void)beginUpload:(FileUpload *)record completion:(void(^)())completionBlock;

- (void)prepareImage:(NSDictionary *)info;
- (NSData *)getImageData:(NSDictionary *)info;
- (UIImage *)makeThumbnail:(UIImage *)image size:(NSInteger)size;

@end
