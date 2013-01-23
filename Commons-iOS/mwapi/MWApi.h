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

@interface MWApi : NSObject{

    NSURL *apiURL_;
    NSString *userID_;
    NSString *userName_;
    NSArray *authCookie_;
    BOOL includeAuthCookie_;
    BOOL isLoggedIn_;
}

@property(nonatomic, readonly) NSURL* apiURL;
@property(nonatomic, readonly) NSString* userID;
@property(nonatomic, readonly) NSString* userName;
@property(nonatomic, readwrite)BOOL includeAuthCookie;
@property(nonatomic, readonly) BOOL isLoggedIn;

- (id)initWithApiUrl: (NSURL*)url;
	
- (id)delegate;
- (void)setDelegate:(id)newDelegate;
- (MWApiRequestBuilder *) action:(NSString *)action;
- (NSArray *) authCookie;
- (void) setAuthCookie:(NSArray *)newAuthCookie;
- (BOOL) validateLogin;
- (BOOL) isLoggedIn;
- (NSString *)loginWithUsername:(NSString *)username andPassword:(NSString *)password;
- (NSString *)loginWithUsername:(NSString *)username andPassword:(NSString *)password withCookiePersistence:(BOOL) doCookiePersist;
- (void) logout;
- (void)uploadFile:(NSString *)filename withFileData:(NSData *)data text:(NSString *)text comment:(NSString *)comment onCompletion:(void(^)(MWApiResult *))block;
- (NSString *)editToken;
- (MWApiResult *)makeRequest:(NSURLRequest *)request;
- (void)makeRequest:(NSURLRequest *)request onCompletion:(void(^)(MWApiResult *))block;;

@end
