//
//  MWNetworkActivityIndicatorManager.h
//  Commons-iOS
//
//  Created by Felix Mo on 2013-01-30.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MWNetworkActivityIndicatorManager : NSObject

+ (MWNetworkActivityIndicatorManager *)sharedManager;

- (void)show;
- (void)hide;

@end
