//
//  FileUpload.h
//  Commons-iOS
//
//  Created by Brion on 1/25/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface FileUpload : NSManagedObject

@property (nonatomic, retain) NSString * assetUrl;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * localFile;
@property (nonatomic, retain) NSString * fileType;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * progress;
@property (nonatomic, retain) NSString * thumbnailFile;
@property (nonatomic, retain) NSNumber * fileSize;

@end
