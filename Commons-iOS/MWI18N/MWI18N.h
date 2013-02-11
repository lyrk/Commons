//
//  MWI18N.h
//  Commons-iOS
//
//  Created by Brion on 2/7/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWMessage.h"
#import "MWMessageStore.h"

@interface MWI18N : NSObject

+ (void)setLanguage:(NSString *)language;
+ (NSString *)fetchMessage:(NSString *)key inLanguage:(NSString *)language;

@end
