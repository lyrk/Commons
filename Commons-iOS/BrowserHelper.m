//
//  BrowserHelper.m
//  Commons-iOS
//
//  Created by Brion on 2/1/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "BrowserHelper.h"
#import "MWI18N/MWMessage.h"

@implementation BrowserHelper

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        [self buildActionSheet:url];
    }
    return self;
}

- (NSString *)openInString:(NSString *)browser
{
    return [MWMessage forKey:@"web-open-in" param:browser].text;
}

- (NSString *)cancelString
{
    return [MWMessage forKey:@"web-cancel"].text;
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
    
    int safariIndex = [sheet addButtonWithTitle:[self openInString:@"Safari"]];
    buttons[safariIndex] = url;

    NSURL *chromeURL = [self chromeURL:url];
    if ([app canOpenURL:chromeURL]) {
        int chromeIndex = [sheet addButtonWithTitle:[self openInString:@"Chrome"]];
        buttons[chromeIndex] = chromeURL;
    }
    
    NSURL *operaURL = [self operaURL:url];
    if ([app canOpenURL:operaURL]) {
        int operaIndex = [sheet addButtonWithTitle:[self openInString:@"Opera"]];
        buttons[operaIndex] = operaURL;
    }
    
    NSURL *dolphinURL = [self dolphinURL:url];
    if ([app canOpenURL:dolphinURL]) {
        int dolphinIndex = [sheet addButtonWithTitle:[self openInString:@"Dolphin"]];
        buttons[dolphinIndex] = dolphinURL;
    }
    
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        // Just tap outside to dismiss on iPad...
        int cancelIndex = [sheet addButtonWithTitle:[self cancelString]];
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
