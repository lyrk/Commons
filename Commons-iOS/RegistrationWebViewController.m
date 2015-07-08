//
//  RegistrationWebViewController.m
//  Commons
//
//  Created by Constantin Müller on 07.07.15.
//  Copyright (c) 2015 Lyrk. All rights reserved.
//

#import "RegistrationWebViewController.h"

@interface RegistrationWebViewController ()

@end

@implementation RegistrationWebViewController

#define REGISTER_ACCOUNT_URL @"https://commons.m.wikimedia.org/w/index.php?title=Special:UserLogin&type=signup"

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
	NSLog(@"view geladen");
	
	NSString *urlAddress = REGISTER_ACCOUNT_URL;
	NSURL *url = [NSURL URLWithString:urlAddress];
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
	[self.webview loadRequest:requestObj];
	//[self.DoneButton setTintColor:[UIColor blackColor]];
	[[UIBarButtonItem appearance] setTintColor:[UIColor redColor]];
}

- (IBAction)DoneButtonPress:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

@end
