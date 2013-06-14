//
//  ImageScrollViewController.m
//  Commons-iOS
//
//  Created by Felix Mo on 2013-02-03.


#import "ImageScrollViewController.h"
#include <math.h>

#define FULL_SCREEN_IMAGE_MIN_ZOOM_SCALE 0.5f
#define FULL_SCREEN_IMAGE_MAX_ZOOM_SCALE 5.0f

// Private
@interface ImageScrollViewController ()

@property (nonatomic, strong) IBOutlet UIScrollView *imageScrollView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;

@end


@implementation ImageScrollViewController{
    float initialScale_;
}


#pragma mark - Property synthesizations

@synthesize imageView;
@synthesize imageScrollView;
@synthesize image;
@synthesize activityIndicator;


#pragma mark - Setters

- (void)setImage:(UIImage *)anImage {
    
    image = anImage;
    
    [self.activityIndicator stopAnimating];
    
    [self.imageView setImage:image];

    [self centerScrollViewContents];

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
    initialScale_ = scale;
}

#pragma mark - Positioning

-(float)getScaleToMakeImageFullscreen
{
    // Determine the scale adjustment required to make the imageView fit completely within the view
    // (Note: this works because the imageView is sized to its image's size when its image is changed)
    CGSize dst = self.view.frame.size;
    CGSize src = self.imageView.frame.size;
    float scale = fminf( dst.width/src.width, dst.height/src.height);

    // Only do this in the case the image is larger than the view - otherwise images smaller than the view
    // are scaled up giving the user a false impression
    return (scale > 1.0f) ? 1.0f : scale;
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
    // From: http://www.raywenderlich.com/10518/how-to-use-uiscrollview-to-scroll-and-zoom-content
    CGSize boundsSize = self.imageScrollView.bounds.size;
    CGRect contentsFrame = self.imageView.frame;
    
    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
    } else {
        contentsFrame.origin.x = 0.0f;
    }
    
    if (contentsFrame.size.height < boundsSize.height) {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
    } else {
        contentsFrame.origin.y = 0.0f;
    }
    
    self.imageView.frame = contentsFrame;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    initialScale_ = 1.0f;
    
    // Center activity indicator view
    CGRect bounds = [[UIScreen mainScreen] bounds];
    self.activityIndicator.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    activityIndicator.autoresizingMask = (UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin);
    
    // Change the appearance of the status bar and navigation bar
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];

    imageView.frame = self.view.frame;
    imageView.backgroundColor = [UIColor blackColor];

    // Setup the scroll view
    imageScrollView.bouncesZoom = YES;
    imageScrollView.delegate = self;
    imageScrollView.clipsToBounds = YES;
    imageScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    imageScrollView.showsHorizontalScrollIndicator = NO;
    imageScrollView.showsVerticalScrollIndicator = NO;
    
    self.imageScrollView.backgroundColor = [UIColor blackColor];
    imageScrollView.frame = self.view.frame;
    
    // Add the imageView to the scrollView as subview
    [imageScrollView addSubview:imageView];
    [imageScrollView setContentMode:UIViewContentModeCenter];
    imageScrollView.contentSize = CGSizeMake(imageView.bounds.size.width, imageView.bounds.size.height);
    
    // Setup UITapGestureRecognizers
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    [singleTap setNumberOfTapsRequired:1];
    [doubleTap setNumberOfTapsRequired:2];
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRight:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    
    // Add the gesture recognizers to the view
    [self.view addGestureRecognizer:singleTap];
    [self.view addGestureRecognizer:doubleTap];
    [self.view addGestureRecognizer:swipeRight];
    
    [self.view bringSubviewToFront:activityIndicator];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    imageScrollView.minimumZoomScale = FULL_SCREEN_IMAGE_MIN_ZOOM_SCALE;
    imageScrollView.maximumZoomScale = FULL_SCREEN_IMAGE_MAX_ZOOM_SCALE;
    imageScrollView.zoomScale = 1.0f;
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    // Restore appearance when popping back
    
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
    
    [self setControlsHidden:NO animated:YES];
}

#pragma mark - UIScrollView

- (void)scrollViewDidZoom:(UIScrollView *)aScrollView {    
    // The scroll view has zoomed, so we need to re-center the contents
    [self centerScrollViewContents];
}

#pragma mark - UIScrollViewDelegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    
    return imageView;
}


#pragma mark - Gestures

- (void)handleSingleTap:(UIGestureRecognizer *)gestureRecognizer {

    // Toggle controls on single tap
    [self performSelector:@selector(toggleControls) withObject:nil afterDelay:0.2f];
}

- (void)handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer {
    
    // Cancel single tap
	[NSObject cancelPreviousPerformRequestsWithTarget:self];

    [self.imageScrollView setZoomScale:initialScale_ animated:YES];
}

- (void)handleSwipeRight:(UIGestureRecognizer *)gestureRecognizer {
    [[self navigationController] popViewControllerAnimated:YES];
}


#pragma mark - Control visibility

// If permanent then timer to hide controls is not activated
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated{
    
	// Status bar and nav bar positioning
    if (self.wantsFullScreenLayout) {
        
        // Get status bar height if visible
        CGFloat statusBarHeight = 0.0f;
        if (![UIApplication sharedApplication].statusBarHidden) {
            CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
            statusBarHeight = MIN(statusBarFrame.size.height, statusBarFrame.size.width);
        }
        
        // Status bar
        if ([UIApplication instancesRespondToSelector:@selector(setStatusBarHidden:withAnimation:)]) {
            [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:animated?UIStatusBarAnimationFade:UIStatusBarAnimationNone];
        }
        
        // Get status bar height if visible
        if (![UIApplication sharedApplication].statusBarHidden) {
            CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
            statusBarHeight = MIN(statusBarFrame.size.height, statusBarFrame.size.width);
        }
        
        // Set navigation bar frame
        CGRect navBarFrame = self.navigationController.navigationBar.frame;
        navBarFrame.origin.y = statusBarHeight;
        self.navigationController.navigationBar.frame = navBarFrame;
    }
    
	// Animate
    if (animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.35f];
    }
    CGFloat alpha = hidden ? 0.0f : 1.0f;
	[self.navigationController.navigationBar setAlpha:alpha];
	if (animated) {
        [UIView commitAnimations];
    }
}

- (BOOL)controlsHidden {
    
    return [UIApplication sharedApplication].isStatusBarHidden;
}

- (void)toggleControls {
    
    [self setControlsHidden:![self controlsHidden] animated:YES];
}

@end
