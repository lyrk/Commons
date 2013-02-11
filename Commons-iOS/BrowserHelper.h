//
//  BrowserHelper.h
//  Commons-iOS
//
//  Created by Brion on 2/1/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BrowserHelper : NSObject <UIActionSheetDelegate>

@property (strong, nonatomic) UIActionSheet *actionSheet;
@property (strong, nonatomic) void (^onCompletion)();
@property (strong, nonatomic) NSMutableArray *browserButtons;

- (id)initWithURL:(NSURL *)url;

- (NSURL *)chromeURL:(NSURL *)url;
- (NSURL *)operaURL:(NSURL *)url;
- (NSURL *)dolphinURL:(NSURL *)url;

- (void)showFromBarButtonItem:(UIBarButtonItem *)item onCompletion:(void(^)())block;
- (void)showInView:(UIView *)view onCompletion:(void(^)())block;

@end
