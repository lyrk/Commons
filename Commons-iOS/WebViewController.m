//
//  WebViewController.m
//  Commons-iOS
//
//  Created by Brion on 2/1/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "WebViewController.h"
#import "BrowserHelper.h"

@interface WebViewController ()

@end

@implementation WebViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    if (self.targetURL != nil) {
        NSURLRequest *request = [NSURLRequest requestWithURL:self.targetURL];
        self.titleNavItem.title = [self.targetURL description];
        [self.webView loadRequest:request];
        self.stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                        target:self
                                                                        action:@selector(stopButtonPushed:)];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setWebView:nil];
    [self setTitleNavItem:nil];
    [self setBackButton:nil];
    [self setRefreshButton:nil];
    [self setStopButton:nil];
    [self setForwardButton:nil];
    [self setActionButton:nil];
    [super viewDidUnload];
}

- (IBAction)backButtonPushed:(id)sender {
    [self.webView goBack];
}

- (IBAction)refreshButtonPushed:(id)sender {
    [self.webView reload];
}

- (IBAction)stopButtonPushed:(id)sender {
    [self.webView stopLoading];
}

- (IBAction)forwardButtonPushed:(id)sender {
    [self.webView goForward];
}

- (IBAction)actionButtonPushed:(id)sender {
    if (self.helper == nil) {
        BrowserHelper *helper = [[BrowserHelper alloc] initWithURL:self.targetURL];
        self.helper = helper;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [helper showFromBarButtonItem:self.actionButton onCompletion:^() {
                self.helper = nil;
            }];
        } else {
            [helper showInView:self.view onCompletion:^() {
                self.helper = nil;
            }];
        }
    }
}

- (void)updateButtons
{
    self.backButton.enabled = self.webView.canGoBack;
    self.forwardButton.enabled = self.webView.canGoForward;
    
    UIBarButtonItem *button;
    if (self.webView.isLoading) {
        button = self.stopButton;
    } else {
        button = self.refreshButton;
    }
    NSMutableArray *items = [self.toolbarItems mutableCopy];
    items[2] = button;
    self.toolbarItems = items;
}

#pragma mark UIWebViewDelegate methods

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self updateButtons];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    self.targetURL = request.URL;
    self.titleNavItem.title = request.URL.description;
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self updateButtons];
    self.titleNavItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self updateButtons];
}




@end
