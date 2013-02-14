//
//  StorageTools.m
//  Commons-iOS
//
//  Created by Daniel Zhang (張道博) on 2/4/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

/**
 * Usage
 * 
 * StorageTools *st = [[StorageTools alloc] init];
 * NSLog(@"total space = %@", [st totalDiskSpace]);
 * NSLog(@"free space = %@", [st freeDiskSpace]);
 */

#import "StorageTools.h"

@interface StorageTools ()
{
    NSNumber *_freeDiskSpace;
    NSNumber *_totalDiskSpace;
    NSArray *_paths;
    NSDictionary *_attributes;
}

-(BOOL)fsAttributesObtained;

@end

@implementation StorageTools

/**
 * Initialization
 * @return object pointer
 */
- (id)init
{
    if (self = [super init]) {
        _totalDiskSpace = nil;
        _freeDiskSpace = nil;
        _paths = nil;
        _attributes = nil;
        return self;
    }
    return nil;
}

/**
 * Read filesystem attributes.
 * @return YES if attributes are obtained, otherwise NO
 */
- (BOOL)fsAttributesObtained
{
    __autoreleasing NSError *error = nil;
    _paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _attributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[_paths lastObject] error:&error];
    if (_attributes) {
        return YES;
    } else {
        NSLog(@"Error: Domain = %@, Code = %d", [error domain], [error code]);
        return NO;
    }
}

/**
 * Get free "disk space".
 * @return free space in bytes where 1 GB = bytes/1024/1024/1024 or NULL if space cannot be obtained.
 */
-(NSNumber *)freeDiskSpace
{
    if ([self fsAttributesObtained] == YES) {
        NSNumber *freeFileSystemSizeInBytes = [_attributes objectForKey:NSFileSystemFreeSize];
        _freeDiskSpace = [NSNumber numberWithLongLong:[freeFileSystemSizeInBytes unsignedLongLongValue]];
        return _freeDiskSpace;
    }
    return NULL;
}

/**
 * Get total "disk space".
 * @return total space in bytes where 1 GB = bytes/1024/1024/1024 or NULL if space cannot be obtained.
 */
-(NSNumber *)totalDiskSpace
{
    if ([self fsAttributesObtained] == YES) {
        NSNumber *fileSystemSizeInBytes = [_attributes objectForKey:NSFileSystemSize];
        _totalDiskSpace = [NSNumber numberWithLongLong:[fileSystemSizeInBytes unsignedLongLongValue]];
        return _totalDiskSpace;
    }
    return NULL;
}

@end
