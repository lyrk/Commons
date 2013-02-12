//
//  MWEventLogging.h
//  Commons-iOS
//
//  Created by Brion on 2/11/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../mwapi/MWApi.h"

@interface MWEventLogging : NSObject

- (id)initWithEndpointURL:(NSURL *)endpoint;

- (void)setDefaults:(NSString *)schemaName defaults:(NSDictionary *)schemaDefaults;
- (MWPromise *)log:(NSString *)schemaName event:(NSDictionary *)event;

@end
