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
#import "MWEventLogging/MWEventLogging.h"
#import "ThumbFetcher.h"

@interface CommonsApp : NSObject

@property (strong, nonatomic) UIWindow *window;
@property (copy, nonatomic) NSString *username;
@property (copy, nonatomic) NSString *password;
@property (nonatomic) BOOL debugMode;
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) MWApi *currentUploadOp;
@property (strong, nonatomic) MWEventLogging *eventLog;
@property (strong, nonatomic) ThumbFetcher *thumbFetcher;

+ (CommonsApp *)singleton;

- (void)initializeApp;
- (NSString *)version;
- (void)loadCredentials;
- (void)saveCredentials;
- (BOOL)processLaunchURL:(NSURL *)url;

- (NSString *)documentRootPath;
- (NSString *)filePath:(NSString *)fileName;
- (NSString *)thumbPath:(NSString *)fileName;
- (NSString *)uniqueFilenameWithExtension:(NSString *)extension;

- (MWPromise *)loadImage:(NSString *)fileName fileType:(NSString *)fileType;
- (MWPromise *)fetchDataURL:(NSURL *)url;
- (MWPromise *)fetchImageURL:(NSURL *)url;
- (MWPromise *)fetchWikiImage:(NSString *)title size:(CGSize)size;

- (void)saveData;
- (NSFetchedResultsController *)fetchUploadRecords;
- (FileUpload *)createUploadRecord;
- (FileUpload *)firstUploadRecord;

- (MWApi *)startApi;
- (NSString *)wikiURLBase;
- (NSURL *)URLForWikiPage:(NSString *)title;
- (MWPromise *)beginUpload:(FileUpload *)record;
- (void)cancelCurrentUpload;

- (MWPromise *)prepareImage:(NSDictionary *)info from:(NSString *)source;
- (void)deleteUploadRecord:(FileUpload *)record;

- (MWPromise *)refreshHistory;

- (NSString *)cleanupTitle:(NSString *)title;

- (NSString *)prettyDate:(NSDate *)date;
- (NSDate *)decodeDate:(NSString *)str;

- (void)log:(NSString *)schemaName event:(NSDictionary *)event;
- (void)deleteAllRecords;

@end
