//
//  MWApi.m
//  MWApi-iOS
//
//  Created by Brion on 11/5/12.
//  Copyright (c) 2012 Wikimedia Foundation. All rights reserved.
//

#import "MWApi.h"
#import "Http.h"
#import "NSURLRequest+DictionaryRequest.h"
#import "MWApiMultipartRequestBuilder.h"

id delegate;

@implementation MWApi

@synthesize apiURL = apiURL_;
@synthesize userID = userID_;
@synthesize userName = userName_;
@synthesize includeAuthCookie = includeAuthCookie_;
@synthesize isLoggedIn = isLoggedIn_;

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

- (BOOL) validateLogin {
    MWApiRequestBuilder *builder = [[self action:@"query"] param:@"meta" :@"userinfo"];
    MWApiResult *result = [self makeRequest:[builder buildRequest:@"GET"]];
    userID_ = [result getStringWithXpath:@"/api/query/userinfo/@id"];
    userName_ = [result getStringWithXpath:@"/api/query/userinfo/@name"];
    return ![userID_ isEqualToString:@"0"];
}

- (NSString *)loginWithUsername:(NSString *)username andPassword:(NSString *)password withCookiePersistence:(BOOL) doCookiePersist
{
    NSString *isSuccess = nil;
    MWApiResult *finalResult = nil;
    MWApiRequestBuilder *builder = [[[self action:@"login"] param:@"lgname" :username] param:@"lgpassword" :password];
    MWApiResult *result = [self makeRequest:[builder buildRequest:@"POST"]];
    NSString *needsToken = [result getStringWithXpath:@"/api/login/@result"];
    if([needsToken isEqualToString:@"NeedToken"]){
        NSString *token = [result getStringWithXpath:@"/api/login/@token"];
        [builder param:@"lgtoken" :token];
        finalResult = [self makeRequest:[builder buildRequest:@"POST"]];
        isSuccess = [finalResult getStringWithXpath:@"/api/login/@result"];
    }
    if ([isSuccess isEqualToString:@"Success"]) {
        isLoggedIn_ = YES;
        if(doCookiePersist){
            [self setAuthCookieFromResult:finalResult];
        }
        return isSuccess;
    }else{
        return needsToken;
    }
}

- (NSString *)loginWithUsername:(NSString *)username andPassword:(NSString *)password {
    return [self loginWithUsername:username andPassword:password withCookiePersistence:NO];
}

- (void) logout {
    MWApiRequestBuilder *builder = [self action:@"logout"];
    [self makeRequest:[builder buildRequest:@"POST"]];
    [self clearAuthCookie];
    isLoggedIn_ = NO;
}

- (MWApiResult *)uploadFile:(NSString *)filename withFileData:(NSData *)data text:(NSString *)text comment:(NSString *)comment {
    
    MWApiMultipartRequestBuilder *builder = [[MWApiMultipartRequestBuilder alloc] initWithApi:self];
    [[[[[[builder param:@"action" :@"upload" ] param:@"token" :[self editToken]]param:@"filename" :filename ] param:@"ignorewarnings" :@"1" ] param:@"comment" :comment] param:@"format" :@"xml"];
    builder = (text != nil)? [builder param:@"text" :text] : builder;
    
    NSURLRequest *uploadRequest = [builder buildRequest:@"POST" withFilename:filename withFileData:data];
    return [builder.api makeRequest:uploadRequest];
}

- (MWApiResult *)uploadFile:(NSString *)filename withFilepath:(NSString *)filepath text:(NSString *)text comment:(NSString *)comment {
    NSData *data = [NSData dataWithContentsOfFile:filepath];
    return [self uploadFile:filename withFileData:data text:text comment:comment];
}

- (MWApiResult *)uploadFile:(NSString *)filename withFilepath:(NSString *)filepath comment:(NSString *)comment {
    return [self uploadFile:filename withFilepath:filepath text:nil comment:comment];
}

- (NSString *)editToken {
    MWApiRequestBuilder *builder = [[self action:@"tokens"] param:@"type" :@"edit"];
    MWApiResult *result = [self makeRequest:[builder buildRequest:@"GET"]];
    return [result getStringWithXpath:@"/api/tokens/@edittoken"];
}

- (MWApiResult *)makeRequest:(NSMutableURLRequest *)request
{
    if(!includeAuthCookie_){
        [self clearAuthCookie];
    }
    MWApiResult *result = [Http retrieveResponseSync:request];
    return result;
}
@end
