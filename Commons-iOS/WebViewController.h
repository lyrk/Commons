//
//  WebViewController.h
//  Commons-iOS
//
//  Created by Brion on 2/1/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BrowserHelper.h"

@interface WebViewController : UIViewController <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UINavigationItem *titleNavItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *refreshButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *stopButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *forwardButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionButton;

@property (copy, nonatomic) NSURL *targetURL;
@property (strong, nonatomic) BrowserHelper *helper;

- (IBAction)backButtonPushed:(id)sender;
- (IBAction)refreshButtonPushed:(id)sender;
- (IBAction)stopButtonPushed:(id)sender;
- (IBAction)forwardButtonPushed:(id)sender;

@end
