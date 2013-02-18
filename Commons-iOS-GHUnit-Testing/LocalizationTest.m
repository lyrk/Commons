//
//  LocalizationTest.m
//  Commons-iOS
//
//  Created by Daniel Zhang (張道博) on 2/16/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <GHUnitIOS/GHUnit.h>
#import "MWMessage.h"

@interface LocalizationTest : GHTestCase

@end

@implementation LocalizationTest

/**
 * Test operation of MWMessage.
 */
-(void)testMWMessageForKey
{
    GHAssertEqualStrings([MWMessage forKey:@"contribs-title"].text, @"My Contributions", @"Test localization value.");
}

@end
