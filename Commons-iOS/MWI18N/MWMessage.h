//
//  MWMessage.h
//  Commons-iOS
//
//  Created by Brion on 2/7/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MWMessage : NSObject

+ (MWMessage *)forKey:(NSString *)key;
+ (MWMessage *)forKey:(NSString *)key param:(NSString *)param;
+ (MWMessage *)forKey:(NSString *)key params:(NSArray *)params;

- (id)initWithKey:(NSString *)key;
- (id)initWithKey:(NSString *)key params:(NSArray *)params;

- (MWMessage *)params:(NSArray *)params;
//- (MWMessage *)rawParams:(NSArray *)params;
//- (MWMessage *)numParams:(NSArray *)params;
//- (MWMessage *)setContext:(MWI18NContext *)context;
- (MWMessage *)inLanguage:(NSString *)lang;

- (NSString *)text;
- (NSString *)plain;
- (BOOL)exists;
- (BOOL)isBlank;
- (BOOL)isDisabled;

@end
