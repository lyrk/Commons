//
//  LoginTest.m
//  Commons-iOS
//
//  Created by Daniel Zhang (張道博) on 2/13/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <GHUnitIOS/GHUnit.h>
#import "MWApi.h"

@interface LoginTest : GHAsyncTestCase

@property(nonatomic, strong) NSURL *url;

@end

@implementation LoginTest

- (BOOL)shouldRunOnMainThread
{
    return NO;
}

- (void)setUp
{
    NSString *wikiURLBase = @"https://test.wikipedia.org";
    self.url = [NSURL URLWithString:[wikiURLBase stringByAppendingString:@"/w/api.php"]];
}

/**
 * Test the login process. Use invalid credentials for now.
 */
- (void)testLogin
{
    [self prepare];

    MWApi *api = [[MWApi alloc] initWithApiUrl:self.url];

    NSString *username = @"BadUsername";
    NSString *password = @"BadPassword";

    MWPromise *login = [api loginWithUsername:username
                                  andPassword:password
                        withCookiePersistence:YES];

    [login done:^(MWApiResult *loginResult) {

        NSLog(@"login: %@", loginResult.data[@"login"][@"result"]);

        if (api.isLoggedIn) {
            [self notify:kGHUnitWaitStatusFailure forSelector:_cmd];
        } else {
            // Credentials invalid
            NSLog(@"Credentials invalid!");
            [self notify:kGHUnitWaitStatusSuccess forSelector:_cmd];
        }
    }];

    [login fail:^(NSError *error) {
        NSLog(@"Login failed: %@", [error localizedDescription]);
        [self notify:kGHUnitWaitStatusFailure forSelector:_cmd];
    }];

    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:15.0];
}

@end