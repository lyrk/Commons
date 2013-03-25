//
//  MWI18N.m
//  Commons-iOS
//
//  Created by Brion on 2/7/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "MWI18N.h"

@implementation MWI18N

static NSString *language_;
static MWMessageStore *store_;

+ (void)setLanguage:(NSString *)language
{
    language_ = [MWI18N filterLanguage:language];
    MWMessageStore *fallback;
    if ([language_ isEqualToString:@"en"]) {
        fallback = nil;
    } else {
        // fixme use the fallbacks table
        fallback = [[MWMessageStore alloc] initWithLanguageCode:@"en" fallback:nil];
    }
    store_ = [[MWMessageStore alloc] initWithLanguageCode:language_ fallback:fallback];
}

+ (NSString *)fetchMessage:(NSString *)key inLanguage:(NSString *)language
{
    // fixme use the language thingy
    return [store_ fetchMessage:key];
}

+ (NSString *)filterLanguage:(NSString *)language
{
    // Force to lowercase to fix eg 'zh-Hans' -> 'zh-hans'
    return [language lowercaseString];
}

@end
