//
//  MWMessageStore.m
//  Commons-iOS
//
//  Created by Brion on 2/7/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "MWMessageStore.h"

@interface MWMessageStore() {
    NSString *language_;
    NSDictionary *store_;
    MWMessageStore *fallback_;
}
@end

@implementation MWMessageStore

- (id)initWithLanguageCode:(NSString *)lang fallback:(MWMessageStore *)fallbackStore
{
    self = [super init];
    if (self) {
        language_ = [lang copy];
        fallback_ = fallbackStore;
        store_ = [self loadMessages];
    }
    return self;
}

- (NSString *)fetchMessage:(NSString *)key
{
    NSString *message = store_[key];
    if (message) {
        return message;
    } else if (fallback_) {
        return [fallback_ fetchMessage:key];
    } else {
        return nil;
    }
}


# pragma mark - Private methods

- (NSDictionary *)loadMessages
{
    NSString *filename = [@"messages-" stringByAppendingString:language_];
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"json"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:path]) {
        NSLog(@"reading messages from %@", path);
        NSData *data = [NSData dataWithContentsOfFile:path];
        return [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    } else {
        NSLog(@"no messages at %@", path);
        return @{};
    }
}

@end
