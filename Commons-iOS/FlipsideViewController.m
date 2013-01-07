//
//  FlipsideViewController.m
//  Commons-iOS
//
//  Created by Brion on 1/7/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "FlipsideViewController.h"
#import "AppDelegate.h"

@interface FlipsideViewController ()

@property (weak, nonatomic) AppDelegate *appDelegate;

@end

@implementation FlipsideViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.UsernameInput.text = self.appDelegate.username;
    self.PasswordInput.text = self.appDelegate.password;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)done:(id)sender
{
    self.appDelegate.username = self.UsernameInput.text;
    self.appDelegate.password = self.PasswordInput.text;
    [self.delegate flipsideViewControllerDidFinish:self];
}

- (void)viewDidUnload {
    [self setUsernameInput:nil];
    [self setPasswordInput:nil];
    [super viewDidUnload];
}
@end
