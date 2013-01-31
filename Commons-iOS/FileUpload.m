//
//  FileUpload.m
//  Commons-iOS
//
//  Created by Brion on 1/25/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "FileUpload.h"


@implementation FileUpload

@dynamic assetUrl;
@dynamic complete;
@dynamic created;
@dynamic desc;
@dynamic localFile;
@dynamic fileType;
@dynamic title;
@dynamic progress;
@dynamic thumbnailFile;
@dynamic fileSize;

- (NSString *)prettySize
{
    float megs = (float)self.fileSize.integerValue / (1024.0f * 1024.0f);
    return [NSString stringWithFormat:@"%0.1f MB", megs];
}

@end
