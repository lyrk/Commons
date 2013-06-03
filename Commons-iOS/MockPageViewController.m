//
//  MockPageViewController.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/20/13.

#import "MockPageViewController.h"
#import "MockPageBackgroundView.h"
#import <QuartzCore/QuartzCore.h>
#import "GettingStartedConstants.h"

@interface MockPageViewController (){
    CGRect mockPagePhotoIBFrame_;
    MockPageBackgroundView *backgroundView_;
}
@end

@implementation MockPageViewController

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
		self.animationDelay = 0.0f;
		self.animationDelayOnce = NO;
    }
    return self;
}

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
						  delay:0.05f
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
                                              self.mockPageLogo.alpha = GETTING_STARTED_MOCK_PAGE_ALPHA_LOGO;

                                              // Make the lines fade out at same rate as the logo
                                              [CATransaction begin];
                                              //match duration to the value of the UIView animateWithDuration: call
                                              [CATransaction setValue:[NSNumber numberWithFloat:0.17f] forKey:kCATransactionAnimationDuration];

                                              // It appears the color setting do need to repeat in verbose manner for animation to tween properly... iirc
                                              backgroundView_.lineOne.strokeColor = [[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:GETTING_STARTED_MOCK_PAGE_ALPHA_LINES] CGColor];
                                              backgroundView_.lineTwo.strokeColor = [[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:GETTING_STARTED_MOCK_PAGE_ALPHA_LINES] CGColor];
                                              backgroundView_.lineThree.strokeColor = [[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:GETTING_STARTED_MOCK_PAGE_ALPHA_LINES] CGColor];
                                              backgroundView_.lineFour.strokeColor = [[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:GETTING_STARTED_MOCK_PAGE_ALPHA_LINES] CGColor];
                                              backgroundView_.lineFive.strokeColor = [[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:GETTING_STARTED_MOCK_PAGE_ALPHA_LINES] CGColor];
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
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, self.animationDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
		[backgroundView_ drawLinesWithAnimation:YES];
		[self revealPhoto];
		if (self.animationDelayOnce) self.animationDelay = 0.0f;
	});
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
