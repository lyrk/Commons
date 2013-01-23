//
//  MWApiResult.m
//  mwapi
//
//  Created by Brion on 11/6/12.
//  Copyright (c) 2012 Wikimedia Foundation. All rights reserved.
//

#import "MWApiResult.h"

@implementation MWApiResult

@synthesize request  = request_;
@synthesize response = response_;
@synthesize error    = error_;
@synthesize data     = data_;

-(id)initWithRequest:(NSURLRequest *)request response:(NSURLResponse *)response responseBody:(NSData *)responseBody errors:(NSError *)error
{
    self = [super init];
    self.request = request;
    self.response = response;
    self.error = error;
    //NSLog(@"%@", [[NSString alloc] initWithData:responseBody encoding:NSUTF8StringEncoding]);
    self.data = [NSJSONSerialization JSONObjectWithData:responseBody options:0 error:NULL];
    return self;
}

@end
