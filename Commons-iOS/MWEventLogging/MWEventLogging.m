//
//  MWEventLogging.m
//  Commons-iOS
//
//  Created by Brion on 2/11/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "MWEventLogging.h"
#import "../mwapi/NSString+Extras.h"

@interface MWEventLogging() {
    NSURL *endpoint_;
    NSMutableDictionary *schemas_;
}
@end

@implementation MWEventLogging

- (id)initWithEndpointURL:(NSURL *)endpoint
{
    self = [super init];
    if (self) {
        endpoint_ = endpoint;
        schemas_ = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSDictionary *)encapsulate:(NSString *)schemaName event:(NSDictionary *)event
{
    // todo port schema validation from JS
    return [event copy];
}

- (MWPromise *)log:(NSString *)schemaName event:(NSDictionary *)event
{
    return [self dispatch:[self encapsulate:schemaName event:event]];
}

- (MWPromise *)dispatch:(NSDictionary *)data
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
    NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *encodedJsonStr = [jsonStr urlEncodedUTF8String];
    NSString *urlStr = [NSString stringWithFormat:@"%@?%@;",
                        endpoint_,
                        encodedJsonStr];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];

    MWDeferred *deferred;
    void (^done)(NSURLResponse*, NSData*, NSError*) = ^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error == nil) {
            [deferred resolve:response];
        } else {
            [deferred reject:response];
        }
    };
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:done];
    return deferred.promise;
}

- (void)setDefaults:(NSString *)schemaName defaults:(NSDictionary *)schemaDefaults
{
    
}

@end
