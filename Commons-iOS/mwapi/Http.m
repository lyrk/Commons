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

+ (void)retrieveResponse:(NSURLRequest *)requestUrl onCompletion:(void(^)(MWApiResult *))completionBlock onProgress:(void(^)(NSInteger,NSInteger))progressBlock;
{
    Http *http = [[Http alloc] initWithRequest:requestUrl];
    [http retrieveResponseOnCompletion:completionBlock onProgress:progressBlock];
}

- (id)initWithRequest:(NSURLRequest *)requestUrl
{
    if ([self init]) {
        requestUrl_ = requestUrl;
        onCompletion_ = nil;
        data_ = nil;
    }
    return self;
}

- (void)retrieveResponseOnCompletion:(void(^)(MWApiResult *))completionBlock onProgress:(void(^)(NSInteger,NSInteger))progressBlock;
{
    onCompletion_ = [completionBlock copy];
    onProgress_ = [progressBlock copy];
    data_ = [[NSMutableData alloc] init];
    connection_ = [[NSURLConnection alloc] initWithRequest:requestUrl_ delegate:self];
    [connection_ start];
    
    [[MWNetworkActivityIndicatorManager sharedManager] show];
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
    
    if (onCompletion_ != nil) {
        NSError *error;
        MWApiResult *result = [[MWApiResult alloc]initWithRequest:requestUrl_ response:response_ responseBody:data_ errors:error];
        onCompletion_(result);

        onCompletion_ = nil;
        onProgress_ = nil;
        data_ = nil;
        response_ = nil;
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
    [[MWNetworkActivityIndicatorManager sharedManager] hide];
}

- (void) connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if (onProgress_ != nil) {
        NSLog(@"%i %i %i", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        onProgress_(totalBytesWritten, totalBytesExpectedToWrite);
    }
}

@end
