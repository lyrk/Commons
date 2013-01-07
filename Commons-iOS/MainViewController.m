//
//  MainViewController.m
//  Commons-iOS
//
//  Created by Brion on 1/7/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "MainViewController.h"
#import "AppDelegate.h"

@interface MainViewController ()
@property (weak, nonatomic) AppDelegate *appDelegate;
@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Flipside View

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        [[segue destinationViewController] setDelegate:self];
    }
}

- (void)viewDidUnload {
    [self setTakePhotoButton:nil];
    [self setGalleryButton:nil];
    [self setDescriptionTextView:nil];
    [self setUploadButton:nil];
    [super viewDidUnload];
}

- (IBAction)pushedPhotoButton:(id)sender {
    NSLog(@"Take photo");
}

- (IBAction)pushedGalleryButton:(id)sender {
    NSLog(@"Open gallery");
}

- (IBAction)pushedUploadFiles:(id)sender {
    NSLog(@"Upload ye files!");

    NSString *username = self.appDelegate.username;
    NSString *password = self.appDelegate.password;
    NSString *desc = self.DescriptionTextView.text;

    NSLog(@"username: %@, password: %@, desc: %@", username, password, desc);
}
@end
