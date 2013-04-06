//
//  AppDelegate.h
//  Commons-iOS
//
//  Created by Brion on 1/7/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <UIKit/UIKit.h>
@class LoadingIndicator;

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
}

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) LoadingIndicator *loadingIndicator;

@end
