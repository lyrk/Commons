//
//  MWApiResult.m
//  mwapi
//
//  Created by Brion on 11/6/12.
//  Copyright (c) 2012 Wikimedia Foundation. All rights reserved.
//

#import "MWApiResult.h"
#import "XPathQuery.h"

@implementation MWApiResult

@synthesize request  = request_;
@synthesize response = response_;
@synthesize responseBody = responseBody_;
@synthesize error    = error_;

-(id)initWithRequest:(NSURLRequest *)request response:(NSURLResponse *)response responseBody:(NSString *)responseBody errors:(NSError *)error
{
    self = [super init];
    self.request = request;
    self.response = response;
    self.responseBody = responseBody;
    self.error = error;
    return self;
}

-(NSArray *) getNodesWithXpath:(NSString *)xpath
{
    if (responseBody_!=nil) {
        return PerformXMLXPathQuery([responseBody_ dataUsingEncoding:NSUTF8StringEncoding],xpath);
    }else{
        return nil;
    }
}	
-(NSNumber *) getNumberWithXpath:(NSString *)xpath
{
    if (responseBody_!=nil) {
        NSArray *arrayNode = PerformXMLXPathQuery([responseBody_ dataUsingEncoding:NSUTF8StringEncoding], xpath);
        if([arrayNode count] != 0){
            NSDictionary *stringDict = [arrayNode objectAtIndex:0];
            NSNumber *value = [stringDict objectForKey:@"nodeContent"];
            return value;
        }else{
            return nil;
        }
    }else{
        return nil;
    }
}

-(NSString *) getStringWithXpath:(NSString *)xpath
{
    if (responseBody_!=nil) {
        NSArray *arrayNode = PerformXMLXPathQuery([responseBody_ dataUsingEncoding:NSUTF8StringEncoding], xpath);
        if([arrayNode count] != 0){
            NSDictionary *stringDict = [arrayNode objectAtIndex:0];
            NSString *value = [stringDict objectForKey:@"nodeContent"];
            return value;
        }else{
            return nil;
        }
    }else{
        return nil;
    }
}


@end
