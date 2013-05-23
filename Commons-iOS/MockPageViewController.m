//
//  MockPageViewController.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/20/13.

#import "MockPageViewController.h"
#import "MockPageBackgroundView.h"
#import <QuartzCore/QuartzCore.h>

@interface MockPageViewController (){
    CGRect mockPagePhotoIBFrame_;
    MockPageBackgroundView *backgroundView_;
}
@end

@implementation MockPageViewController

- (void)viewDidLoad
{
    mockPagePhotoIBFrame_ = self.mockPagePhoto.frame;
    backgroundView_ = (MockPageBackgroundView *)self.view;

    [super viewDidLoad];
    
    [self reset];
}

-(void) revealPhoto
{    
    [UIView animateWithDuration:0.17f
						  delay:0.35f
						options:UIViewAnimationOptionTransitionNone
					 animations:^{
                         // Slide the photo in from off-screen right
                         self.mockPagePhoto.frame = mockPagePhotoIBFrame_;
                         // Partial photo fade-in
                         self.mockPagePhoto.alpha = 0.5f;
					 }
					 completion:^(BOOL finished){
                         [UIView animateWithDuration:0.17f
                                               delay:0.01f
                                             options:UIViewAnimationOptionBeginFromCurrentState
                                          animations:^{
                                              
                                              // Complete photo fade-in
                                              self.mockPagePhoto.alpha = 1.0f;

                                              // Partial logo fade-out
                                              self.mockPageLogo.alpha = 0.5;

                                              // Make the lines fade out at same rate as the logo
                                              [CATransaction begin];
                                              //match duration to the value of the UIView animateWithDuration: call
                                              [CATransaction setValue:[NSNumber numberWithFloat:0.17f] forKey:kCATransactionAnimationDuration];

                                              // It appears the color setting do need to repeat in verbose manner for animation to tween properly... iirc
                                              backgroundView_.lineOne.strokeColor = [[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5] CGColor];
                                              backgroundView_.lineTwo.strokeColor = [[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5] CGColor];
                                              backgroundView_.lineThree.strokeColor = [[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5] CGColor];
                                              backgroundView_.lineFour.strokeColor = [[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5] CGColor];
                                              backgroundView_.lineFive.strokeColor = [[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5] CGColor];
                                              [CATransaction commit];
                                              
                                              // Make the photo swell
                                              self.mockPagePhoto.transform = CGAffineTransformMakeScale(1.4f, 1.4f);
                                              
                                          }
                                          completion:^(BOOL finished){
                                              [UIView animateWithDuration:0.17f
                                                                    delay:0.0f
                                                                  options:UIViewAnimationOptionTransitionNone
                                                               animations:^{
                                                                   // Return the photo to original size
                                                                   self.mockPagePhoto.transform = CGAffineTransformIdentity;
                                                               }
                                                               completion:^(BOOL finished){
                                                               }];
                                          }];
					 }];
}

-(void) hidePhoto
{
    // Move the photo off-screen right
    self.mockPagePhoto.frame = CGRectOffset(mockPagePhotoIBFrame_, 75.0f, 0.0f);
    self.mockPagePhoto.alpha = 0.0f;
}

-(void)viewDidAppear:(BOOL)animated
{
    [backgroundView_ drawLinesWithAnimation:YES];
    [self revealPhoto];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reset];
}

-(void)reset
{
    // Logo fade-in
    self.mockPageLogo.alpha = 1.0;
    
    [backgroundView_ reset];
    [backgroundView_ drawLinesWithAnimation:NO];
    
    [self hidePhoto];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [self reset];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
