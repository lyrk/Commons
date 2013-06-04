//
//  NavigationController.m
//  Commons-iOS
//
//  Created by Monte Hurd on 4/3/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "NavigationController.h"

@implementation NavigationController

-(BOOL)shouldAutorotate
{
    // Delegate the auto rotation decision to the top-most view controller
    // Nice as it allows the auto rotation decision to be made by the currently used view controller
    return [self.topViewController shouldAutorotate];
}

-(NSUInteger)supportedInterfaceOrientations{
    return [self.topViewController supportedInterfaceOrientations];
}

@end
