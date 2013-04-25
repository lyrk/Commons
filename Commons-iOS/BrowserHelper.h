//
//  BrowserHelper.h
//  Commons-iOS
//
//  Created by Brion on 2/1/13.

#import <Foundation/Foundation.h>

@interface BrowserHelper : NSObject

- (NSArray *)getInstalledSupportedBrowserNames;
- (bool)isBrowserInstalled:(NSString *)browserName;
- (NSURL *)formatURL:(NSURL*)urlWithProtocol forBrowser:(NSString *)browser;

@end
