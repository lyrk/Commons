//
//  MWApi.h
//  MWApi-iOS
//
//  Created by Brion on 11/5/12.
//  Copyright (c) 2012 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWApiResult.h"
#import "MWApiRequestBuilder.h"
#import "MWHttp.h"
#import "MWDeferred.h"

#define MW_ERROR_CODE(x) ([(x).domain isEqualToString:@"MediaWiki API"] ? (x).userInfo[@"MW error code"] : @"network")
#define MW_ERROR_INFO(x) ([(x).domain isEqualToString:@"MediaWiki API"] ? (x).userInfo[@"MW error info"] : (x).description)

@interface MWApi : NSObject{

    NSURL *apiURL_;
    NSString *userID_;
    NSString *userName_;
    NSArray *authCookie_;
    BOOL includeAuthCookie_;
    BOOL isLoggedIn_;
    MWHttp *connection_;
}

@property(nonatomic, readonly) NSURL* apiURL;
@property(nonatomic, readonly) NSString* userID;
@property(nonatomic, readonly) NSString* userName;
@property(nonatomic, readwrite)BOOL includeAuthCookie;
@property(nonatomic, readonly) BOOL isLoggedIn;
@property(nonatomic, readonly) MWHttp *connection;

- (id)initWithApiUrl: (NSURL*)url;

- (MWApiRequestBuilder *) action:(NSString *)action;
- (NSArray *) authCookie;
- (void) setAuthCookie:(NSArray *)newAuthCookie;
- (MWPromise *) validateLogin;
- (BOOL) isLoggedIn;
- (MWPromise *)loginWithUsername:(NSString *)username andPassword:(NSString *)password;
- (MWPromise *)loginWithUsername:(NSString *)username andPassword:(NSString *)password withCookiePersistence:(BOOL)doCookiePersist;
- (MWPromise *)logout;
- (MWPromise *)uploadFile:(NSString *)filename withFileData:(NSData *)data text:(NSString *)text comment:(NSString *)comment;
- (MWPromise *)editToken;
- (MWPromise *)makeRequest:(NSURLRequest *)request;

- (MWPromise *)getRequest:(NSDictionary *)params;

- (void)cancelCurrentRequest;

@end
