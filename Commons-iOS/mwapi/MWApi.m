//
//  MWApi.m
//  MWApi-iOS
//
//  Created by Brion on 11/5/12.
//  Copyright (c) 2012 Wikimedia Foundation. All rights reserved.
//

#import "MWApi.h"
#import "NSURLRequest+DictionaryRequest.h"
#import "MWApiMultipartRequestBuilder.h"

id delegate;

@implementation MWApi

@synthesize apiURL = apiURL_;
@synthesize userID = userID_;
@synthesize userName = userName_;
@synthesize includeAuthCookie = includeAuthCookie_;
@synthesize isLoggedIn = isLoggedIn_;
@synthesize connection = connection_;

- (id)initWithApiUrl: (NSURL*)url {
    self = [super init];
    if(self){
        apiURL_ = url;
        includeAuthCookie_ = YES;
        [self clearAuthCookie]; // Clearing previous authCookies from the shared cookie storage
    }
    return self;
}

- (id)delegate {
    return delegate;
}

- (void)setDelegate:(id)newDelegate {
    delegate = newDelegate;
}

- (MWApiRequestBuilder *) action:(NSString *)action {
    MWApiRequestBuilder *builder = [[MWApiRequestBuilder alloc]initWithApi:self];
    [builder param:@"action" :action];
    return builder;
}
    	
- (NSArray *) authCookie {
    return authCookie_;
}

- (void) setAuthCookie:(NSArray *)newAuthCookie{
    authCookie_ = newAuthCookie;
    [[ NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies: authCookie_ forURL: apiURL_ mainDocumentURL: nil ];
}

- (void) setAuthCookieFromResult:(MWApiResult *)result {
    authCookie_ = [ NSHTTPCookie cookiesWithResponseHeaderFields:[(NSHTTPURLResponse *)result.response allHeaderFields] forURL:apiURL_];
    [[ NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies: authCookie_ forURL: apiURL_ mainDocumentURL: nil ];
}

-(void)clearAuthCookie{
    authCookie_ = nil;
    NSArray *previousCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:apiURL_];
    for (NSHTTPCookie *each in previousCookies)
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:each];
}

- (MWPromise *) validateLogin
{
    MWDeferred *deferred = [[MWDeferred alloc] init];
    MWApiRequestBuilder *builder = [[self action:@"query"] param:@"meta" :@"userinfo"];
    MWPromise *login = [self makeRequest:[builder buildRequest:@"GET"]];
    [login done:^(MWApiResult *result) {
        userID_ = [result.data[@"query"][@"userinfo"][@"id"] copy];
        userName_ = [result.data[@"query"][@"userinfo"][@"name"] copy];
        BOOL loggedIn = ![userID_ isEqualToString:@"0"];
        [deferred resolve:[NSNumber numberWithBool:(loggedIn)]];
    }];
    [login fail:^(NSError *error) {
        NSLog(@"Failed to validate login: %@", [error localizedDescription]);
        [deferred reject:error];
    }];
    return deferred.promise;
}

- (MWPromise *)loginWithUsername:(NSString *)username andPassword:(NSString *)password withCookiePersistence:(BOOL) doCookiePersist
{
    MWApiRequestBuilder *builder = [self action:@"login"];
    [builder params: @{
     @"lgname": username,
     @"lgpassword": password
     }];
    MWDeferred *deferred = [[MWDeferred alloc] init];

    MWDeferred *finalLogin = [[MWDeferred alloc] init];

    MWPromise *loginPromise = [self makeRequest:[builder buildRequest:@"POST"]];
    [loginPromise done:^(MWApiResult *result) {
        if([result.data[@"login"][@"result"] isEqualToString:@"NeedToken"]){
            NSString *token = result.data[@"login"][@"token"];
            [builder param:@"lgtoken" :token];
            MWPromise *second = [self makeRequest:[builder buildRequest:@"POST"]];
            [second done:^(MWApiResult *result) {
                [finalLogin resolve:result];
            }];
            [second fail:^(NSError *error) {
                [finalLogin reject:error];
            }];
        } else {
            [finalLogin resolve:result];
        }
    }];
    [loginPromise fail:^(NSError *err) {
        [deferred reject:err];
    }];

    MWPromise *finalPromise = finalLogin.promise;
    [finalPromise done:^(MWApiResult *result) {
        if ([result.data[@"login"][@"result"] isEqualToString:@"Success"]) {
            isLoggedIn_ = YES;
            if(doCookiePersist){
                [self setAuthCookieFromResult:result];
            }
        }
        [deferred resolve:result];
    }];
    [finalPromise fail:^(NSError *err) {
        [deferred reject:err];
    }];
        
    return deferred.promise;
}

- (MWPromise *)loginWithUsername:(NSString *)username andPassword:(NSString *)password
{
    return [self loginWithUsername:username andPassword:password withCookiePersistence:NO];
}

- (MWPromise *)logout {
    MWDeferred *deferred = [[MWDeferred alloc] init];

    MWApiRequestBuilder *builder = [self action:@"logout"];
    MWPromise *logout = [self makeRequest:[builder buildRequest:@"POST"]];

    [logout done:^(MWApiResult *result) {
        [self clearAuthCookie];
        isLoggedIn_ = NO;
        [deferred resolve:result];
    }];
     
    [logout fail:^(NSError *error) {
        NSLog(@"Failed to log out user: %@", [error localizedDescription]);
        [deferred reject:error];
    }];
    
    return deferred.promise;
}

- (MWPromise *)uploadFile:(NSString *)filename withFileData:(NSData *)data text:(NSString *)text comment:(NSString *)comment
{
    MWDeferred *deferred = [[MWDeferred alloc] init];

    MWPromise *token = [self editToken];
    [token done:^(NSString *editToken){
        MWApiMultipartRequestBuilder *builder = [[MWApiMultipartRequestBuilder alloc] initWithApi:self];
        [builder params: @{
             @"action": @"upload",
             @"token": editToken,
             @"filename": filename,
             @"ignorewarnings": @"1",
             @"comment": comment,
             @"text": (text != nil) ? text : @"",
             @"format": @"json"
        }];
        
        NSURLRequest *uploadRequest = [builder buildRequest:@"POST" withFilename:filename withFileData:data];
        MWPromise *upload = [builder.api makeRequest:uploadRequest];
        [upload pipe:deferred];
    }];
    [token fail:^(NSError *err) {
        [deferred reject:err];
    }];

    return deferred.promise;
}

- (MWPromise *)editToken {
    MWDeferred *deferred = [[MWDeferred alloc] init];

    MWApiRequestBuilder *builder = [[self action:@"tokens"] param:@"type" :@"edit"];
    MWPromise *token = [self makeRequest:[builder buildRequest:@"GET"]];
    [token done:^(MWApiResult *result) {
        [deferred resolve:[result.data[@"tokens"][@"edittoken"] copy]];
    }];
    [token fail:^(NSError *err) {
        [deferred reject:err];
    }];

    return deferred.promise;
}

- (MWPromise *)makeRequest:(NSMutableURLRequest *)request
{
    if(!includeAuthCookie_){
        [self clearAuthCookie];
    }
    
    connection_ = [[Http alloc] initWithRequest:request];
    return [connection_ retrieveResponse];
}

- (void)cancelCurrentRequest {
    [self.connection cancel];
}

- (MWPromise *)getRequest:(NSDictionary *)params
{
    MWApiMultipartRequestBuilder *builder = [[MWApiMultipartRequestBuilder alloc] initWithApi:self];
    [builder params:params];
    [builder param:@"format" :@"json"];
    NSURLRequest *request = [builder buildRequest:@"GET"];
    return [self makeRequest:request];
}

@end
