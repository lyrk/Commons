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
    void (^onFailure_)(NSError *);
    NSMutableData *data_;
    NSURLResponse *response_;
    NSURLConnection *connection_;
}

+ (void)retrieveResponse:(NSURLRequest *)requestUrl onCompletion:(void(^)(MWApiResult *))completionBlock onProgress:(void(^)(NSInteger,NSInteger))progressBlock onFailure:(void(^)(NSError *))failureBlock;

- (id)initWithRequest:(NSURLRequest *)requestUrl;
- (void)retrieveResponseOnCompletion:(void(^)(MWApiResult *))completionBlock onProgress:(void(^)(NSInteger,NSInteger))progressBlock onFailure:(void(^)(NSError *))failureBlock;
- (void)cancel;

@end
