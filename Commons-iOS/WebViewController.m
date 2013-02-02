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
        [self.webView loadRequest:request];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setActionButton:nil];
    [self setWebView:nil];
    [self setTitleBar:nil];
    [super viewDidUnload];
}

- (IBAction)actionButtonPushed:(id)sender {
    BrowserHelper *helper = [[BrowserHelper alloc] initWithURL:self.targetURL];
    self.helper = helper;
    UIActionSheet *sheet = helper.actionSheet;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [sheet showFromBarButtonItem:self.actionButton animated:YES];
    } else {
        [sheet showInView:self.view];
    }
}

@end
