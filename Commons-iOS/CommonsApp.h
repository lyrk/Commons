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
#import "mwapi/MWApi.h"

@interface CommonsApp : NSObject

@property (strong, nonatomic) UIWindow *window;
@property (copy, nonatomic) NSString *username;
@property (copy, nonatomic) NSString *password;
@property (nonatomic) BOOL debugMode;
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) MWApi *currentUploadOp;

+ (CommonsApp *)singleton;

- (void)initializeApp;
- (void)loadCredentials;
- (void)saveCredentials;
- (BOOL)processLaunchURL:(NSURL *)url;

- (NSString *)documentRootPath;
- (NSString *)filePath:(NSString *)fileName;
- (NSString *)thumbPath:(NSString *)fileName;
- (NSString *)uniqueFilenameWithExtension:(NSString *)extension;
- (UIImage *)loadImage:(NSString *)fileName;
- (UIImage *)loadThumbnail:(NSString *)fileName;

- (void)saveData;
- (NSFetchedResultsController *)fetchUploadRecords;
- (FileUpload *)createUploadRecord;
- (FileUpload *)firstUploadRecord;

- (MWApi *)startApi;
- (void)beginUpload:(FileUpload *)record completion:(void(^)())completionBlock;
- (void)cancelCurrentUpload;

- (void)prepareImage:(NSDictionary *)info onCompletion:(void(^)())completionBlock;
- (void)deleteUploadRecord:(FileUpload *)record;
- (UIImage *)makeThumbnail:(UIImage *)image size:(NSInteger)size;

- (void)refreshHistory;

- (void)fetchImage:(NSURL *)url onCompletion:(void(^)(UIImage *image))block;
- (void)fetchWikiImage:(NSString *)title size:(CGSize)size onCompletion:(void(^)(UIImage *))block;

- (NSString *)prettyDate:(NSDate *)date;

@end
