//
//  MWMessage.m
//  Commons-iOS
//
//  Created by Brion on 2/7/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "MWI18N.h"

@interface MWMessage() {
    NSString *key_;
    NSString *lang_;
    NSMutableArray *params_;
}
@end

@implementation MWMessage

+ (MWMessage *)forKey:(NSString *)key
{
    return [[MWMessage alloc] initWithKey:key];
}

+ (MWMessage *)forKey:(NSString *)key param:(NSString *)param
{
    return [[MWMessage alloc] initWithKey:key params:@[param]];
}

+ (MWMessage *)forKey:(NSString *)key params:(NSArray *)params
{
    return [[MWMessage alloc] initWithKey:key params:params];
}

- (id)initWithKey:(NSString *)key
{
    self = [super init];
    if (self) {
        key_ = [key copy];
        //lang_ = [[MWI18N language] copy];
        lang_ = @"en";
        params_ = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithKey:(NSString *)key params:(NSArray *)params
{
    self = [self initWithKey:key];
    if (self) {
        [self params:params];
    }
    return self;
}

- (MWMessage *)params:(NSArray *)params
{
    for (NSString *param in params) {
        [params_ addObject:param];
    }
    return self;
}

//- (MWMessage *)rawParams:(NSArray *)params;
//- (MWMessage *)numParams:(NSArray *)params;
//- (MWMessage *)setContext:(MWI18NContext *)context;

- (MWMessage *)inLanguage:(NSString *)lang
{
    return self;
}

- (NSString *)text
{
    NSString *msg = [self fetchMessage];

    // Compact whitespace. Ensures no line breaks. Needed because there are some line breaks in
    // some of the language strings files and iOS 7 may require apps respect users system font
    // size preferences, which means text size may not be known in advance, which means breaks
    // should not be hard-coded because varying text size means break locations will vary as well.
    msg = [msg stringByReplacingOccurrencesOfString:@"\\s+" withString:@" "
                       options:NSRegularExpressionSearch
                       range:NSMakeRange(0, msg.length)];

    // Uncomment to double strings for testing
    // msg = [NSString stringWithFormat:@"%@ %@", msg, msg];

    // fixme parse?
    return [self replaceParameters:msg];
}

- (NSString *)plain
{
    NSString *msg = [self fetchMessage];
    return [self replaceParameters:msg];
}

- (BOOL)exists
{
    NSString *msg = [self fetchMessage];
    return (msg != nil);
}

- (BOOL)isBlank
{
    return (self.text.length == 0);
}

- (BOOL)isDisabled
{
    return (self.isBlank || [self.text isEqualToString:@"-"]);
}

#pragma mark Private methods

- (NSString *)fetchMessage
{
    return [MWI18N fetchMessage:key_ inLanguage:lang_];
}

- (NSString *)replaceParameters:(NSString *)msg
{
    // hacky mchack
    NSString *out = [msg copy];
    for (int i = 1; i < (params_.count+1); i++) {
        NSString *key = [NSString stringWithFormat:@"$%d", i];
        NSString *param = params_[i - 1];
        if (param != nil) {
            // this may fail if '$2' appears in parameter 1, etc
            out = [out stringByReplacingOccurrencesOfString:key withString:param];
        }
    }
    return out;
}

@end
