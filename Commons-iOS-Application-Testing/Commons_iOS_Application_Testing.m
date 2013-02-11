//
//  Commons_iOS_Application_Testing.m
//  Commons-iOS-Application-Testing
//
//  Created by Daniel Zhang (張道博) on 2/2/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "Commons_iOS_Application_Testing.h"
#import "CommonsApp.h"

@implementation Commons_iOS_Application_Testing

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testSingleton
{
    CommonsApp *app1 = [CommonsApp singleton];
    CommonsApp *app2 = [CommonsApp singleton];
    STAssertEquals(app1, app2, @"Singleton should return same object every time");
}

@end
