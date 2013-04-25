//
//  MWApi.h
//  MWApi-iOS
//
//  Created by Brion on 11/5/12.
//  Copyright (c) 2012 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWApiRequestBuilder.h"
#import "MWHttp.h"
#import "MWDeferred.h"

#define MW_ERROR_API            100
#define MW_ERROR_IMAGE_FETCH    200
#define MW_ERROR_UPLOAD_CANCEL  300

@interface MWApi : NSObject{

    NSURL *apiURL_;
    NSString *userID_;
    NSString *userName_;
    NSArray *authCookie_;
    BOOL isLoggedIn_;
    MWHttp *connection_;
}

@property(nonatomic, readonly) NSURL* apiURL;
@property(nonatomic, readonly) NSString* userID;
@property(nonatomic, readonly) NSString* userName;
@property(nonatomic, readonly) BOOL isLoggedIn;
@property(nonatomic, readonly) MWHttp *connection;

- (id)initWithApiUrl: (NSURL*)url;

- (MWApiRequestBuilder *) action:(NSString *)action;
- (NSArray *) authCookie;
- (MWPromise *) validateLogin;
- (BOOL) isLoggedIn;
- (MWPromise *)loginWithUsername:(NSString *)username andPassword:(NSString *)password;
- (MWPromise *)logout;
- (MWPromise *)uploadFile:(NSString *)filename withFileData:(NSData *)data text:(NSString *)text comment:(NSString *)comment;
- (MWPromise *)editToken;
- (MWPromise *)makeRequest:(NSURLRequest *)request;

- (MWPromise *)getRequest:(NSDictionary *)params;

- (void)cancelCurrentRequest;

- (NSString *)formatTimestamp:(NSDate *)timestamp;

+ (NSString *)getResultForError:(NSError*)error;
+ (NSString *)getMessageForError:(NSError*)error;

@end
