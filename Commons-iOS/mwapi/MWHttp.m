//
//  Http.m
//  mwapi
//
//  Created by Jaikumar Bhambhwani on 11/10/12.
//  Copyright (c) 2012 Wikimedia Foundation. All rights reserved.
//

#import "MWHttp.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "MWApi.h"

@implementation MWHttp

+ (MWPromise *)retrieveResponse:(NSURLRequest *)requestUrl
{
    MWHttp *http = [[MWHttp alloc] initWithRequest:requestUrl];
    return [http retrieveResponse];
}

- (id)initWithRequest:(NSURLRequest *)requestUrl
{
    if (self = [self init]) {
        requestUrl_ = requestUrl;
        deferred_ = [[MWDeferred alloc] init];
        data_ = nil;
    }
    return self;
}

- (MWPromise *)retrieveResponse
{
    data_ = [[NSMutableData alloc] init];
    connection_ = [[NSURLConnection alloc] initWithRequest:requestUrl_ delegate:self];
    [connection_ start];

    [[MWNetworkActivityIndicatorManager sharedManager] show];

    return deferred_.promise;
}

- (void)cancel {
    [connection_ cancel];
    
    NSError *error = [NSError errorWithDomain:@"MediaWiki API" code:MW_ERROR_UPLOAD_CANCEL userInfo:@{}];
    [deferred_ reject:error];
    
    [[MWNetworkActivityIndicatorManager sharedManager] hide];
}

#pragma mark - NSConnectionDelegate methods

- (void)connection:(NSURLConnection*) connection didReceiveResponse:(NSURLResponse *)response
{
    response_ = response;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [[MWNetworkActivityIndicatorManager sharedManager] hide];

    // fixme check for HTTP error responses

    NSError *error;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data_ options:0 error:&error];

    if (result == nil) {
        // JSON deserialization failure
        [deferred_ reject:error];
    } else if (result[@"error"]) {
        NSLog(@"%@", result);
        // Generic error result from the API.
        NSDictionary *info = @{
                               @"MW error code": result[@"error"][@"code"],
                               @"MW error info": result[@"error"][@"info"]
                             };
        error = [NSError errorWithDomain:@"MediaWiki API" code:MW_ERROR_API userInfo:info];
        [deferred_ reject:error];
    } else {
        // Non-error result. Doesn't necessarily mean success -- check the documentation
        // for the API methods you're calling to see if there's a response value.
        
        // fixme should we just return the JSON dictionary directly instead of a MWResponse?
        [deferred_ resolve:result];
    }
    [self cleanUp];
}

- (void)connection:(NSURLConnection*) connection didReceiveData:(NSData *)data
{
    if (data_ != nil) {
        [data_ appendData: data];
    }
}

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[MWNetworkActivityIndicatorManager sharedManager] hide];
    [deferred_ reject:error];
    [self cleanUp];
}

- (void) connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    NSDictionary *dict = @{
                           @"sent": [NSNumber numberWithInteger:totalBytesWritten],
                           @"total": [NSNumber numberWithInteger:totalBytesExpectedToWrite]
                         };
    [deferred_ notify:dict];
}

- (void)cleanUp
{
    requestUrl_ = nil;
    deferred_ = nil;
    response_ = nil;
    data_ = nil;
    connection_ = nil;
}

@end
