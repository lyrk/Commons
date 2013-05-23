//
//  GotItViewController.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/21/13.

#import "GotItViewController.h"

@interface GotItViewController (){
    UITapGestureRecognizer *tapRecognizer;
}

@end

@implementation GotItViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.mockPageContainerView.transform = CGAffineTransformMakeScale(0.5, 0.5);
    self.mockBadPhotoContainerView.transform = CGAffineTransformMakeScale(0.5, 0.5);

    tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
	[self.view addGestureRecognizer:tapRecognizer];
}

-(void)handleTap
{
    [self drawAttentionToYesButton];
}

-(void)drawAttentionToYesButton
{
    [UIView animateWithDuration:0.13f
                          delay:0.0f
                        options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         self.gotItLabel.alpha = 0.5f;
                         self.yesButton.transform = CGAffineTransformMakeScale(1.08f, 1.08f);
                     }
                     completion:^(BOOL finished){
                         [UIView animateWithDuration:0.13f
                                               delay:0.0f
                                             options:UIViewAnimationOptionTransitionNone
                                          animations:^{
                                              self.gotItLabel.alpha = 1.0f;
                                              self.yesButton.transform = CGAffineTransformIdentity;
                                          }
                                          completion:^(BOOL finished){
                                          }];
                     }];
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
