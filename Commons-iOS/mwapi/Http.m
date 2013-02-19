//
//  Http.m
//  mwapi
//
//  Created by Jaikumar Bhambhwani on 11/10/12.
//  Copyright (c) 2012 Wikimedia Foundation. All rights reserved.
//

#import "Http.h"
#import "MWNetworkActivityIndicatorManager.h"


@implementation Http

+ (MWPromise *)retrieveResponse:(NSURLRequest *)requestUrl
{
    Http *http = [[Http alloc] initWithRequest:requestUrl];
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
    
    [[MWNetworkActivityIndicatorManager sharedManager] hide];
}

#pragma mark - NSConnectionDelegate methods

- (void)connection:(NSURLConnection*) connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"Response recieved");
    response_ = response;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"finished loading");
    
    [[MWNetworkActivityIndicatorManager sharedManager] hide];
    
    NSError *error;
    // fixme check for HTTP error responses
    // fixme check for invalid JSON
    MWApiResult *result = [[MWApiResult alloc]initWithRequest:requestUrl_ response:response_ responseBody:data_ errors:error];
    if (result.data[@"error"]) {
        NSLog(@"API error! %@", result.data);
        // Generic error result from the API.
        NSDictionary *info = @{
                               @"MW error code": result.data[@"error"][@"code"],
                               @"MW error info": result.data[@"error"][@"info"]
                              };
        NSError *error = [NSError errorWithDomain:@"MediaWiki API" code:100 userInfo:info];
        [deferred_ reject:error];
    } else {
        NSLog(@"API success! %@", result.data);
        // Non-error result. Doesn't necessarily mean success -- check the documentation
        // for the API methods you're calling to see if there's a response value.
        
        // fixme should we just return the JSON dictionary directly instead of a MWResponse?
        [deferred_ resolve:result];
    }
}

- (void)connection:(NSURLConnection*) connection didReceiveData:(NSData *)data
{
    NSLog(@"Data recieved");
    if (data_ != nil) {
        [data_ appendData: data];
    }
}

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Request failed with error: %@", [error localizedDescription]);
    [[MWNetworkActivityIndicatorManager sharedManager] hide];
    [deferred_ reject:error];
}

- (void) connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    NSDictionary *dict = @{
                           @"sent": [NSNumber numberWithInteger:totalBytesWritten],
                           @"total": [NSNumber numberWithInteger:totalBytesExpectedToWrite]
                        };
    [deferred_ notify:dict];
}

@end
