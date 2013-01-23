//
//  Http.m
//  mwapi
//
//  Created by Jaikumar Bhambhwani on 11/10/12.
//  Copyright (c) 2012 Wikimedia Foundation. All rights reserved.
//

#import "Http.h"

@implementation Http

+ (void)retrieveResponse:(NSURLRequest *)requestUrl onCompletion:(void(^)(MWApiResult *))block
{
    Http *http = [[Http alloc] initWithRequest:requestUrl];
    [http retrieveResponseAsyncWithBlock: block];
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

- (void)retrieveResponseAsyncWithBlock:(void(^)(MWApiResult *))block;
{
    onCompletion_ = [block copy];
    data_ = [[NSMutableData alloc] init];
    NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:requestUrl_ delegate:self];
    [connection start];
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
    if (onCompletion_ != nil) {
        NSError *error;
        MWApiResult *result = [[MWApiResult alloc]initWithRequest:requestUrl_ response:response_ responseBody:data_ errors:error];
        onCompletion_(result);

        onCompletion_ = nil;
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
    
}

- (void) connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    
}

@end
