//
//  MWApiRequestBuilder.h
//  mwapi
//
//  Created by Brion on 11/6/12.
//  Copyright (c) 2012 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWApiResult.h"
@class MWApi;

@interface MWApiRequestBuilder : NSObject
{
    NSMutableDictionary *params_;
    MWApi *api_;
    NSString *dataType_;
}
@property(nonatomic,retain) NSMutableDictionary *params;
@property(nonatomic,retain) MWApi *api;

-(id) initWithApi:(MWApi *)mwapi;
-(id) param:(NSString *) key : (id) value;
-(NSURLRequest *)buildRequest:(NSString *)requestType;
-(void)dataType:(NSString *)type;

@end
