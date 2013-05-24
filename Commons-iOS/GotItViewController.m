//
//  GotItViewController.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/21/13.

#import "GotItViewController.h"
#import "GettingStartedConstants.h"
#import "MWI18N.h"

@interface GotItViewController (){
    UITapGestureRecognizer *tapRecognizer_;
}

@end

@implementation GotItViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = GETTING_STARTED_BG_COLOR;
    [self.yesButton setTitleColor:GETTING_STARTED_BG_COLOR forState:UIControlStateNormal];
    
    self.mockPageContainerView.transform = CGAffineTransformMakeScale(0.5, 0.5);
    self.mockBadPhotoContainerView.transform = CGAffineTransformMakeScale(0.5, 0.5);

    tapRecognizer_ = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
	[self.view addGestureRecognizer:tapRecognizer_];
    
    self.gotItLabel.text = [MWMessage forKey:@"getting-started-got-it-label"].text;
    [self.yesButton setTitle:[MWMessage forKey:@"getting-started-yes-button"].text forState:UIControlStateNormal];
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
