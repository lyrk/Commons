//
//  WebViewController.h
//  Commons-iOS
//
//  Created by Brion on 2/1/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BrowserHelper.h"

@interface WebViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionButton;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UINavigationItem *TitleBar;

@property (copy, nonatomic) NSURL *targetURL;
@property (strong, nonatomic) BrowserHelper *helper;

- (IBAction)actionButtonPushed:(id)sender;

@end
