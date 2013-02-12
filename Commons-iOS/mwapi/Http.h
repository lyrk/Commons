//
//  Http.h
//  mwapi
//
//  Created by Jaikumar Bhambhwani on 11/10/12.
//  Copyright (c) 2012 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWApiResult.h"
#import "MWDeferred.h"

@interface Http : NSObject <NSURLConnectionDataDelegate> {
    NSURLRequest *requestUrl_;
    MWDeferred *deferred_;
    NSMutableData *data_;
    NSURLResponse *response_;
    NSURLConnection *connection_;
}

+ (MWPromise *)retrieveResponse:(NSURLRequest *)requestUrl;

- (id)initWithRequest:(NSURLRequest *)requestUrl;
- (MWPromise *)retrieveResponse;
- (void)cancel;

@end
