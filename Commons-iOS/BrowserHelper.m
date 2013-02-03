//
//  BrowserHelper.m
//  Commons-iOS
//
//  Created by Brion on 2/1/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "BrowserHelper.h"

@implementation BrowserHelper

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        [self buildActionSheet:url];
    }
    return self;
}

- (void)buildActionSheet:(NSURL *)url
{
    UIApplication *app = [UIApplication sharedApplication];
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:nil];
    NSMutableArray *buttons = [[NSMutableArray alloc] init];
    
    int safariIndex = [sheet addButtonWithTitle:@"Open in Safari"];
    buttons[safariIndex] = url;

    NSURL *chromeURL = [self chromeURL:url];
    if ([app canOpenURL:chromeURL]) {
        int chromeIndex = [sheet addButtonWithTitle:@"Open in Chrome"];
        buttons[chromeIndex] = chromeURL;
    }
    
    NSURL *operaURL = [self operaURL:url];
    if ([app canOpenURL:operaURL]) {
        int operaIndex = [sheet addButtonWithTitle:@"Open in Opera"];
        buttons[operaIndex] = operaURL;
    }
    
    NSURL *dolphinURL = [self dolphinURL:url];
    if ([app canOpenURL:dolphinURL]) {
        int dolphinIndex = [sheet addButtonWithTitle:@"Open in Dolphin"];
        buttons[dolphinIndex] = dolphinURL;
    }
    
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        // Just tap outside to dismiss on iPad...
        int cancelIndex = [sheet addButtonWithTitle:@"Cancel"];
        sheet.cancelButtonIndex = cancelIndex;
    }
    
    self.browserButtons = buttons;
    self.actionSheet = sheet;
}

- (NSURL *)chromeURL:(NSURL *)url
{
    NSString *proto = url.scheme;
    if ([proto isEqualToString:@"http"]) {
        return [[NSURL alloc] initWithScheme:@"googlechrome" host:url.host path:url.path];
    } else if ([proto isEqualToString:@"https"]) {
        return [[NSURL alloc] initWithScheme:@"googlechromes" host:url.host path:url.path];
    } else {
        // kaboom
        return nil;
    }
}

- (NSURL *)operaURL:(NSURL *)url
{
    NSString *proto = url.scheme;
    if ([proto isEqualToString:@"http"]) {
        return [[NSURL alloc] initWithScheme:@"ohttp" host:url.host path:url.path];
    } else if ([proto isEqualToString:@"https"]) {
        return [[NSURL alloc] initWithScheme:@"ohttps" host:url.host path:url.path];
    } else {
        // kaboom
        return nil;
    }
}

- (NSURL *)dolphinURL:(NSURL *)url
{
    NSString *urlStr = [url description];
    return [NSURL URLWithString:[@"dolphin://" stringByAppendingString:urlStr]];
}

- (void)showFromBarButtonItem:(UIBarButtonItem *)item onCompletion:(void(^)())block
{
    self.onCompletion = [block copy];
    [self.actionSheet showFromBarButtonItem:item animated:YES];
}

- (void)showInView:(UIView *)view onCompletion:(void(^)())block
{
    self.onCompletion = [block copy];
    [self.actionSheet showInView:view];
}

#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex < self.browserButtons.count) {
        NSURL *url = self.browserButtons[buttonIndex];
        [UIApplication.sharedApplication openURL:url];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    void (^onCompletion)() = self.onCompletion;
    self.browserButtons = nil;
    self.actionSheet = nil;
    self.onCompletion = nil;
    onCompletion();
}

@end
