//
//  Http.h
//  mwapi
//
//  Created by Jaikumar Bhambhwani on 11/10/12.
//  Copyright (c) 2012 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWApiResult.h"

@interface Http : NSObject <NSURLConnectionDataDelegate> {
    NSURLRequest *requestUrl_;
    void (^onCompletion_)(MWApiResult *);
    NSMutableData *data_;
}

+ (MWApiResult *)retrieveResponseSync:(NSURLRequest *)requestUrl;

- (id)initWithRequest:(NSURLRequest *)requestUrl;
- (MWApiResult *)retrieveResponseSync;
- (void)retrieveResponseAsyncWithBlock:(void(^)(MWApiResult *))block;

@end
