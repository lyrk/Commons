//
//  ImageScrollViewController.m
//  Commons-iOS
//
//  Created by Felix Mo on 2013-02-03.


#import "ImageScrollViewController.h"
#include <math.h>
#import <QuartzCore/QuartzCore.h>

#define FULL_SCREEN_IMAGE_MIN_ZOOM_SCALE 0.5f
#define FULL_SCREEN_IMAGE_MAX_ZOOM_SCALE 5.0f

// Defines how dark the black overlay above the image can become when details slide up over the image
#define FULL_SCREEN_IMAGE_MAX_OVERLAY_ALPHA 0.8f

// Private
@interface ImageScrollViewController ()

@end

@implementation ImageScrollViewController{
    UIView *overlayView_;
}

#pragma mark - Property synthesizations

@synthesize imageView;
@synthesize imageScrollView;
@synthesize image;

#pragma mark - Setters

- (void)setImage:(UIImage *)anImage {
    
    image = anImage;
    
    [self.imageView setImage:image];

    // Resize imageView to match new image size
    [self sizeImageViewToItsImage];
    
    // And zoom so image fits
    float scale = [self getScaleToMakeImageFullscreen];

    if (scale < imageScrollView.minimumZoomScale) {
        // Must adjust minimumZoomScale down or the image won't be able to be shrunken to fit
        imageScrollView.minimumZoomScale = scale * 0.5;
    }

    [self.imageScrollView setZoomScale:scale animated:NO];

    // Remember the scale so it can be easily returned to
    self.initialScale = scale;
}

#pragma mark - Positioning

-(float)getScaleToMakeImageFullscreen
{
    // Determine the scale adjustment required to make the imageView fit completely within the view
    // (Note: this works because the imageView is sized to its image's size when its image is changed)
    CGSize dst = self.view.frame.size;
    CGSize src = self.imageView.frame.size;
    float scale = fminf( dst.width/src.width, dst.height/src.height);

    // (Turned this off because on iPad the images need to be scaled up a bit to fill larger screen better)
    // Only do this in the case the image is larger than the view - otherwise images smaller than the view
    // are scaled up giving the user a false impression
    // return (scale > 1.0f) ? 1.0f : scale;

    // Increased the scale just a bit so the image has just a bit of overlap
    // Look nicer as the image then extends beyond the nav bar buttons
    scale *= (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 1.05f : 1.30f;

    return scale;
}

-(void)sizeImageViewToItsImage
{
    // Sizes and keeps the previous center
    CGPoint p = self.imageView.center;
    CGRect f = self.imageView.frame;
    f.size = image.size;
    self.imageView.frame = f;
    self.imageView.center = p;
}

- (void)centerScrollViewContents {
    UIView *subView = self.imageView;
    
    CGFloat offsetX = (self.imageScrollView.bounds.size.width > self.imageScrollView.contentSize.width)?
    (self.imageScrollView.bounds.size.width - self.imageScrollView.contentSize.width) * 0.5 : 0.0;
    
    CGFloat offsetY = (self.imageScrollView.bounds.size.height > self.imageScrollView.contentSize.height)?
    (self.imageScrollView.bounds.size.height - self.imageScrollView.contentSize.height) * 0.5 : 0.0;
    
    subView.center = CGPointMake(self.imageScrollView.contentSize.width * 0.5 + offsetX,
                                 self.imageScrollView.contentSize.height * 0.5 + offsetY);
    
    CGPoint centerOffset = CGPointMake(
                                       (imageScrollView.contentSize.width/2) - (self.imageScrollView.bounds.size.width/2),
                                       (imageScrollView.contentSize.height/2) - (self.imageScrollView.bounds.size.height/2)
                                       );
    
    if(self.imageScrollView.bounds.size.width > self.imageScrollView.contentSize.width){
        centerOffset.x = 0;
    }
    if(self.imageScrollView.bounds.size.height > self.imageScrollView.contentSize.height){
        centerOffset.y = 0;
    }
    
    [self.imageScrollView setContentOffset:centerOffset animated:NO];
}

#pragma mark - Nav

-(void)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.initialScale = 1.0f;

    
    // Change back button to be an arrow
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"\U000025C0\U0000FE0E"
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:self
                                                                            action:@selector(backButtonPressed:)];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
    UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleTopMargin |
    UIViewAutoresizingFlexibleHeight |
    UIViewAutoresizingFlexibleBottomMargin;

    overlayView_ = [[UIView alloc] initWithFrame:self.view.bounds];
    overlayView_.autoresizingMask = self.view.autoresizingMask;
    [self.view addSubview:overlayView_];
    overlayView_.userInteractionEnabled = NO;
    overlayView_.backgroundColor = [UIColor clearColor];
    
    /*
     // Center activity indicator view
     CGRect bounds = [[UIScreen mainScreen] bounds];
    
     self.activityIndicator.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
     activityIndicator.autoresizingMask = (UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin);
    
     // Change the appearance of the status bar and navigation bar
     [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
     [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
     */

    // Setup the scroll view
    imageScrollView.bouncesZoom = YES;
    imageScrollView.delegate = self;
    imageScrollView.clipsToBounds = YES;
    imageScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    imageScrollView.showsHorizontalScrollIndicator = NO;
    imageScrollView.showsVerticalScrollIndicator = NO;
    imageScrollView.delaysContentTouches = NO;
    
    imageScrollView.backgroundColor = [UIColor clearColor];
    imageView.backgroundColor = [UIColor clearColor];
    
    // Add the imageView to the scrollView as subview
    [imageScrollView addSubview:imageView];
    [imageScrollView setContentMode:UIViewContentModeCenter];
    imageScrollView.contentSize = CGSizeMake(imageView.bounds.size.width, imageView.bounds.size.height);
    
    // Setup UITapGestureRecognizers
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRight:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    
    // Add the gesture recognizers to the view
    [self.view addGestureRecognizer:swipeRight];

    imageScrollView.minimumZoomScale = FULL_SCREEN_IMAGE_MIN_ZOOM_SCALE;
    imageScrollView.maximumZoomScale = FULL_SCREEN_IMAGE_MAX_ZOOM_SCALE;
    imageScrollView.zoomScale = 1.0f;

	// Don't make the view background clear or the space surrounding the image will
	// stop responding to touch events - perhaps because uiview's "hitTest:withEvent:"
	// doesn't fire if the touched view's alpha is < 0.01f?
    self.view.backgroundColor = [UIColor blackColor];
	
    [self.view setMultipleTouchEnabled:YES];
    self.imageScrollView.backgroundColor = [UIColor clearColor];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
}

/*
-(void)viewWillAppear:(BOOL)animated
{
//    [self.activityIndicator startAnimating];

    [super viewWillAppear:animated];
}
*/

#pragma mark - UIScrollView

- (void)scrollViewDidZoom:(UIScrollView *)aScrollView {    
    // The scroll view has zoomed, so we need to re-center the contents
    [self centerScrollViewContents];
}

#pragma mark - UIScrollViewDelegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    
    return imageView;
}

#pragma mark - Zoom

-(void)resetInitialZoomScaleAnimated:(BOOL)animated
{
    [self.imageScrollView setZoomScale:self.initialScale animated:animated];
}

- (void)handleSwipeRight:(UIGestureRecognizer *)gestureRecognizer {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Rotation

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self resetInitialZoomScaleAnimated:YES];

    [self centerScrollViewContents];
}

-(BOOL)shouldAutorotate
{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutomaticallyForwardRotationMethods{
    // This method is called to determine whether to
    // automatically forward rotation-related containment
    // callbacks to child view controllers.
    return YES;
}

-(BOOL)shouldAutomaticallyForwardAppearanceMethods{
    // This method is called to determine whether to
    // automatically forward appearance-related containment
    //  callbacks to child view controllers.
    return YES;    
}

#pragma mark - Details Scroll

-(void)setDetailsScrollNormal:(float)detailsScrollNormal
{    
    _detailsScrollNormal = detailsScrollNormal;
    
    /*
    float overlayAlpha = MIN(FULL_SCREEN_IMAGE_MAX_OVERLAY_ALPHA, 1.0f - detailsScrollNormal);
    
    overlayView_.backgroundColor = [UIColor colorWithWhite:0.0f alpha:overlayAlpha];
    */
}

-(void)clearOverlay
{
	overlayView_.backgroundColor = [UIColor clearColor];
}

@end
