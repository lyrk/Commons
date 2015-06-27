//
//  Category.m
//  Commons-iOS
//
//  Created by Brion on 5/8/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "CommonsCategory.h"


@implementation CommonsCategory

@dynamic name;
@dynamic lastUsed;
@dynamic timesUsed;

- (void)touch
{
    self.lastUsed = [NSDate date];
}

- (void)incTimedUsed
{
    self.timesUsed = [NSNumber numberWithInteger:self.timesUsed.integerValue + 1];
    [self touch];
}

@end
