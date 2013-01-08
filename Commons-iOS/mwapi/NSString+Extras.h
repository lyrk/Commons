//
//  NSString+URLEncoding.h
//  mwapi
//
//  Created by Jaikumar Bhambhwani on 11/10/12.
//  Copyright (c) 2012 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Extras)

- (NSString *)urlEncodedUTF8String;
+ (NSString *)sha1:(NSString *)dataFromString isFile:(BOOL)isFile;

@end
