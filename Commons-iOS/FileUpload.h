//
//  FileUpload.h
//  Commons-iOS
//
//  Created by Brion on 1/24/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface FileUpload : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * assetUrl;
@property (nonatomic, retain) NSString * filePath;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * fileType;
@property (nonatomic, retain) NSData * thumbnail;

@end
