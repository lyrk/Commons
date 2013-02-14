//
//  StorageTools.h
//  Commons-iOS
//
//  Created by Daniel Zhang (張道博) on 2/4/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StorageTools : NSObject

-(NSNumber *)freeDiskSpace;
-(NSNumber *)totalDiskSpace;

@end
