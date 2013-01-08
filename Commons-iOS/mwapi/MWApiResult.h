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
    NSString *responseBody_;
    NSError *error_;
}

@property (nonatomic,retain) NSURLRequest *request;
@property (nonatomic,retain) NSURLResponse *response;
@property (nonatomic,retain) NSString *responseBody;
@property (nonatomic,retain) NSError *error;

-(id) initWithRequest:(NSURLRequest *)request response:(NSURLResponse *)response responseBody:(NSString *)body errors:(NSError *)error;
-(NSArray *) getNodesWithXpath:(NSString *)xpath;
-(NSNumber *) getNumberWithXpath:(NSString *)xpath;
-(NSString *) getStringWithXpath:(NSString *)xpath;

@end
