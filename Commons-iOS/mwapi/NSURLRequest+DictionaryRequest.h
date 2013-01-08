//
//  NSURLRequest+DictionaryPost.h
//  mwapi
//
//  Created by Jaikumar Bhambhwani on 11/10/12.
//  Copyright (c) 2012 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLRequest (DictionaryRequest)

+ (NSURLRequest *)postRequestWithURL:(NSURL *)url
                          parameters:(NSDictionary *)parameters;
+ (NSURLRequest *)getRequestWithURL:(NSURL *)url
                          parameters:(NSDictionary *)parameters;
@end
