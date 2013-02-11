//
//  MWMessageStore.h
//  Commons-iOS
//
//  Created by Brion on 2/7/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MWMessageStore : NSObject

- (id)initWithLanguageCode:(NSString *)lang fallback:(MWMessageStore *)fallbackStore;
- (NSString *)fetchMessage:(NSString *)key;

@end
