//
//  GotItViewController.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/21/13.

#import "GotItViewController.h"

@interface GotItViewController ()

@end

@implementation GotItViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.mockPageContainerView.transform = CGAffineTransformMakeScale(0.5, 0.5);
    self.mockBadPhotoContainerView.transform = CGAffineTransformMakeScale(0.5, 0.5);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)yesButtonPushed:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissModalView" object:nil userInfo:nil];
}

@end
