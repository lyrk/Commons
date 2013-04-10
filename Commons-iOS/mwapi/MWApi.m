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

@implementation MWApi

@synthesize apiURL = apiURL_;
@synthesize userID = userID_;
@synthesize userName = userName_;
@synthesize isLoggedIn = isLoggedIn_;
@synthesize connection = connection_;

- (id)initWithApiUrl: (NSURL*)url {
    self = [super init];
    if(self){
        apiURL_ = url;
        [self clearAuthCookie]; // Clearing previous authCookies from the shared cookie storage
    }
    return self;
}

- (MWApiRequestBuilder *) action:(NSString *)action {
    MWApiRequestBuilder *builder = [[MWApiRequestBuilder alloc]initWithApi:self];
    [builder param:@"action" :action];
    return builder;
}
    	
- (NSArray *) authCookie {
    return authCookie_;
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
    [login done:^(NSDictionary *result) {
        userID_ = [result[@"query"][@"userinfo"][@"id"] copy];
        userName_ = [result[@"query"][@"userinfo"][@"name"] copy];
        BOOL loggedIn = ![userID_ isEqualToString:@"0"];
        [deferred resolve:[NSNumber numberWithBool:(loggedIn)]];
    }];
    [login fail:^(NSError *error) {
        NSLog(@"Failed to validate login: %@", [error localizedDescription]);
        [deferred reject:error];
    }];
    return deferred.promise;
}

- (MWPromise *)loginWithUsername:(NSString *)username andPassword:(NSString *)password
{
    MWApiRequestBuilder *builder = [self action:@"login"];
    [builder params: @{
     @"lgname": username,
     @"lgpassword": password
     }];
    MWDeferred *deferred = [[MWDeferred alloc] init];

    MWDeferred *finalLogin = [[MWDeferred alloc] init];

    MWPromise *loginPromise = [self makeRequest:[builder buildRequest:@"POST"]];
    [loginPromise done:^(NSDictionary *result) {
        if([result[@"login"][@"result"] isEqualToString:@"NeedToken"]){
            NSString *token = result[@"login"][@"token"];
            [builder param:@"lgtoken" :token];
            MWPromise *second = [self makeRequest:[builder buildRequest:@"POST"]];
            [second done:^(NSDictionary *result) {
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
    [finalPromise done:^(NSDictionary *result) {
        if ([result[@"login"][@"result"] isEqualToString:@"Success"]) {
            isLoggedIn_ = YES;
        }
        [deferred resolve:result];
    }];
    [finalPromise fail:^(NSError *err) {
        [deferred reject:err];
    }];
        
    return deferred.promise;
}

- (MWPromise *)logout {
    MWDeferred *deferred = [[MWDeferred alloc] init];

    MWApiRequestBuilder *builder = [self action:@"logout"];
    MWPromise *logout = [self makeRequest:[builder buildRequest:@"POST"]];

    [logout done:^(NSDictionary *result) {
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
    [token done:^(NSDictionary *result) {
        [deferred resolve:[result[@"tokens"][@"edittoken"] copy]];
    }];
    [token fail:^(NSError *err) {
        [deferred reject:err];
    }];

    return deferred.promise;
}

- (MWPromise *)makeRequest:(NSMutableURLRequest *)request
{
    connection_ = [[MWHttp alloc] initWithRequest:request];
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

- (NSString *)formatTimestamp:(NSDate *)timestamp
{
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit |
                                                          NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit)
                                                fromDate:timestamp];
    return [NSString stringWithFormat:@"%04d%02d%02d%02d%02d%02d",
            components.year, components.month, components.day,
            components.hour, components.minute, components.second];
}

@end
