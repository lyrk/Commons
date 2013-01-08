//
//  Http.h
//  mwapi
//
//  Created by Jaikumar Bhambhwani on 11/10/12.
//  Copyright (c) 2012 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWApiResult.h"

@interface Http : NSObject <NSURLConnectionDataDelegate>

+ (MWApiResult *)retrieveResponseSync:(NSURLRequest *)requestUrl;
- (void)retrieveResponseAsync:(NSURLRequest *)requestUrl;

@end
