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
    MockPageBackgroundView *backgroundView_;
}

@property (strong, nonatomic) NSLayoutConstraint *mockPagePhotoOffscreenConstraint;
@property (strong, nonatomic) NSLayoutConstraint *mockPagePhotoOnscreenConstraint;

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
    // Constraints for hiding/showing mockPagePhoto
    self.mockPagePhotoOffscreenConstraint = [NSLayoutConstraint constraintWithItem:self.mockPagePhoto
                                                                         attribute:NSLayoutAttributeLeft
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeRight
                                                                        multiplier:1
                                                                          constant:24];
    
    self.mockPagePhotoOnscreenConstraint = [NSLayoutConstraint constraintWithItem:self.mockPagePhoto
                                                                        attribute:NSLayoutAttributeRight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.view
                                                                        attribute:NSLayoutAttributeRight
                                                                       multiplier:1
                                                                         constant:-24];
    
    [self.view addConstraint:self.mockPagePhotoOffscreenConstraint];
    
    backgroundView_ = (MockPageBackgroundView *)self.view;

    [super viewDidLoad];
    
    [self reset];
}

-(void) revealPhoto
{
    [self.view removeConstraint:self.mockPagePhotoOffscreenConstraint];
    [self.view addConstraint:self.mockPagePhotoOnscreenConstraint];

    [UIView animateWithDuration:0.17f
						  delay:0.05f
						options:UIViewAnimationOptionTransitionNone
					 animations:^{

                         // Partial photo fade-in
                         self.mockPagePhoto.alpha = 0.5f;
                         
                         // Cause the constraint changes to be animated
                         [self.view layoutIfNeeded];
					 }
					 completion:^(BOOL finished){

                         // Make the lines fade out at same rate as the logo
                         [CATransaction begin];
                         //match duration to the value of the UIView animateWithDuration: call
                         [CATransaction setValue:[NSNumber numberWithFloat:0.2f] forKey:kCATransactionAnimationDuration];
                         CGColorRef color = [[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:GETTING_STARTED_MOCK_PAGE_ALPHA_LINES] CGColor];
                         backgroundView_.lineOne.strokeColor = color;
                         backgroundView_.lineTwo.strokeColor = color;
                         backgroundView_.lineThree.strokeColor = color;
                         backgroundView_.lineFour.strokeColor = color;
                         backgroundView_.lineFive.strokeColor = color;
                         [CATransaction commit];

                         // Swell the photo
                         CABasicAnimation *swellMockPagePhoto = [CABasicAnimation animationWithKeyPath:@"transform"];
                         swellMockPagePhoto.autoreverses = YES;
                         swellMockPagePhoto.duration = 0.17f;
                         [swellMockPagePhoto setRemovedOnCompletion:YES];
                         [swellMockPagePhoto setBeginTime:CACurrentMediaTime() + 0.0f];
                         swellMockPagePhoto.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.4, 1.4, 1)];
                         [self.mockPagePhoto.layer addAnimation:swellMockPagePhoto forKey:nil];

                         [UIView animateWithDuration:0.2f
                                               delay:0.01f
                                             options:UIViewAnimationOptionBeginFromCurrentState
                                          animations:^{
                                              
                                              // Complete photo fade-in
                                              self.mockPagePhoto.alpha = 1.0f;

                                              // Partial logo fade-out
                                              self.mockPageLogo.alpha = GETTING_STARTED_MOCK_PAGE_ALPHA_LOGO;
                                          }
                                          completion:^(BOOL finished){
                                          }];
					 }];
}

-(void) hidePhoto
{
    // Move the photo off-screen right
    [self.view removeConstraint:self.mockPagePhotoOnscreenConstraint];
    [self.view addConstraint:self.mockPagePhotoOffscreenConstraint];
    [self.view layoutIfNeeded];

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
