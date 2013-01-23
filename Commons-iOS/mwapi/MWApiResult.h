//
//  MWApiResult.h
//  mwapi
//
//  Created by Brion on 11/6/12.
//  Copyright (c) 2012 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MWApiResult : NSObject{
    NSURLRequest *request_;
    NSURLResponse *response_;
    NSError *error_;
    NSDictionary *data_;
}

@property (nonatomic,retain) NSURLRequest *request;
@property (nonatomic,retain) NSURLResponse *response;
@property (nonatomic,retain) NSString *responseBody;
@property (nonatomic,retain) NSError *error;
@property (nonatomic,retain) NSDictionary *data;

-(id) initWithRequest:(NSURLRequest *)request response:(NSURLResponse *)response responseBody:(NSData *)body errors:(NSError *)error;

@end
