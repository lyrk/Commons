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
    void (^onProgress_)(NSInteger,NSInteger);
    NSMutableData *data_;
    NSURLResponse *response_;
    NSURLConnection *connection_;
}

+ (void)retrieveResponse:(NSURLRequest *)requestUrl onCompletion:(void(^)(MWApiResult *))completionBlock onProgress:(void(^)(NSInteger,NSInteger))progressBlock;

- (id)initWithRequest:(NSURLRequest *)requestUrl;
- (void)retrieveResponseOnCompletion:(void(^)(MWApiResult *))completionBlock onProgress:(void(^)(NSInteger,NSInteger))progressBlock;
- (void)cancel;

@end
