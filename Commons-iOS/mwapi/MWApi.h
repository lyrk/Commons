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
#import "Http.h"
#import "MWDeferred.h"

@interface MWApi : NSObject{

    NSURL *apiURL_;
    NSString *userID_;
    NSString *userName_;
    NSArray *authCookie_;
    BOOL includeAuthCookie_;
    BOOL isLoggedIn_;
    Http *connection_;
}

@property(nonatomic, readonly) NSURL* apiURL;
@property(nonatomic, readonly) NSString* userID;
@property(nonatomic, readonly) NSString* userName;
@property(nonatomic, readwrite)BOOL includeAuthCookie;
@property(nonatomic, readonly) BOOL isLoggedIn;
@property(nonatomic, readonly) Http *connection;

- (id)initWithApiUrl: (NSURL*)url;
	
- (id)delegate;
- (void)setDelegate:(id)newDelegate;
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
