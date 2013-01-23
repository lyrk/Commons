//
//  Http.m
//  mwapi
//
//  Created by Jaikumar Bhambhwani on 11/10/12.
//  Copyright (c) 2012 Wikimedia Foundation. All rights reserved.
//

#import "Http.h"

@implementation Http

+ (MWApiResult *)retrieveResponseSync:(NSURLRequest *)requestUrl
{
    NSURLResponse *response;
    NSError *error;
    NSData* data = [NSURLConnection sendSynchronousRequest:requestUrl returningResponse:&response error:&error];
    MWApiResult *result = [[MWApiResult alloc]initWithRequest:requestUrl response:response responseBody:data errors:error];
    return result;
}

- (void)retrieveResponseAsync:(NSURLRequest *)requestUrl
{
    NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:requestUrl delegate:self];
    [connection start];
}

#pragma mark - NSConnectionDelegate methods

- (void)connection:(NSURLConnection*) connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"Response recieved");	    
}		

- (void)connection:(NSURLConnection*) connection didReceiveData:(NSData *)data
{
    NSLog(@"Data recieved");
}

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    
}

- (void) connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    
}

@end
