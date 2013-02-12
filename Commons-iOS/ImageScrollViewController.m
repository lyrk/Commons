//
//  ImageScrollViewController.m
//  Commons-iOS
//
//  Created by Felix Mo on 2013-02-03.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//


#import "ImageScrollViewController.h"


// Private
@interface ImageScrollViewController ()

@property (nonatomic, strong) IBOutlet UIScrollView *imageScrollView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) NSTimer *controlsVisibilityTimer;

@end


@implementation ImageScrollViewController


#pragma mark - Property synthesizations

@synthesize imageView;
@synthesize imageScrollView;
@synthesize image;
@synthesize controlsVisibilityTimer;
@synthesize activityIndicator;


#pragma mark - Setters

- (void)setImage:(UIImage *)anImage {
    
    image = anImage;
    
    [self.activityIndicator stopAnimating];
    
    [self.imageView setImage:image];
    
    CGRect imageViewFrame;
    imageViewFrame.origin = CGPointZero;
    imageViewFrame.size = self.image.size;
    self.imageView.frame = imageViewFrame;
    self.imageScrollView.contentSize = imageViewFrame.size;
	
	// Sizes
    CGSize boundsSize = self.imageScrollView.bounds.size;
    CGSize imageSize = self.imageView.frame.size;
    
    // Calculate min. scale
    CGFloat xScale = boundsSize.width / imageSize.width;    // scale to fit the width of the image
    CGFloat yScale = boundsSize.height / imageSize.height;  // scale to fit the height of the image
    CGFloat minScale = MIN(xScale, yScale);                 // use the lesser of the two to fit the entire image in the view
	
	// If the image is smaller than the screen then show it at a min. scale of 1
	if (xScale > 1.0f && yScale > 1.0f) {
		minScale = 1.0f;
	}
    
	// Calculate max. scale
	CGFloat maxScale = 1.0f;
	if ([UIScreen instancesRespondToSelector:@selector(scale)]) {
		maxScale = maxScale / [[UIScreen mainScreen] scale];
	}
	
	// Set values
	self.imageScrollView.maximumZoomScale = maxScale;
	self.imageScrollView.minimumZoomScale = minScale;
	self.imageScrollView.zoomScale = minScale;
}


#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    // Center activity indicator view
    CGRect bounds = [[UIScreen mainScreen] bounds];
    self.activityIndicator.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    activityIndicator.autoresizingMask = (UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin);
    
    // Change the appearance of the status bar and navigation bar
    //[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
    //[self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
        
    // Setup the scroll view
    imageScrollView.bouncesZoom = YES;
    imageScrollView.delegate = self;
    imageScrollView.clipsToBounds = YES;
    imageScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    imageScrollView.showsHorizontalScrollIndicator = NO;
    imageScrollView.showsVerticalScrollIndicator = NO;
    
    // Add the imageView to the scrollView as subview
    [imageScrollView addSubview:imageView];
    [imageScrollView setContentMode:UIViewContentModeCenter];
    imageScrollView.contentSize = CGSizeMake(imageView.bounds.size.width, imageView.bounds.size.height);
    
    // Setup UITapGestureRecognizers
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    [singleTap setNumberOfTapsRequired:1];
    [doubleTap setNumberOfTapsRequired:2];
    
    // Add the gesture recognizers to the image view
    [imageView addGestureRecognizer:singleTap];
    [imageView addGestureRecognizer:doubleTap];
    
    // Load the image if it's there
    if (self.image) {
        [self setImage:image];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    // Restore appearance when popping back
    
    //[self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    //[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    [self setControlsHidden:NO animated:YES permanent:YES];
}


#pragma mark - UIScrollView

- (void)scrollViewDidZoom:(UIScrollView *)aScrollView {
    
    CGFloat offsetX = (imageScrollView.bounds.size.width > imageScrollView.contentSize.width) ? (imageScrollView.bounds.size.width - imageScrollView.contentSize.width) * 0.5f : 0.0f;
    CGFloat offsetY = (imageScrollView.bounds.size.height > imageScrollView.contentSize.height) ? (imageScrollView.bounds.size.height - imageScrollView.contentSize.height) * 0.5f : 0.0f;
    
    imageView.center = CGPointMake(imageScrollView.contentSize.width * 0.5f + offsetX, imageScrollView.contentSize.height * 0.5f + offsetY);
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
	[self cancelControlHiding];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    
	[self cancelControlHiding];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
	[self hideControlsAfterDelay];
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
    
    // Get touch location
    CGPoint touchPoint = [gestureRecognizer locationInView:self.imageView];
    
    // Zoom
	if (self.imageScrollView.zoomScale == self.imageScrollView.maximumZoomScale) {
		
		// Zoom out
		[self.imageScrollView setZoomScale:self.imageScrollView.minimumZoomScale animated:YES];
		
	} else {
		
		// Zoom in
		[self.imageScrollView zoomToRect:CGRectMake(touchPoint.x, touchPoint.y, 1.0f, 1.0f) animated:YES];
		
	}
    
    // Delay controls
	[self hideControlsAfterDelay];
}


#pragma mark - Control visibility

// If permanent then timer to hide controls is not activated
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent {
    
    // Cancel any timers
    [self cancelControlHiding];
	
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
	
	// Control hiding timer; will cancel existing timer but only begin hiding if they are visible
	if (!permanent) {
        [self hideControlsAfterDelay];
    }
    
}

- (void)cancelControlHiding {
    
	// If a timer exists then cancel it
	if (controlsVisibilityTimer) {
		[controlsVisibilityTimer invalidate];
		controlsVisibilityTimer = nil;
	}
}

// Enable/disable control visiblity timer
- (void)hideControlsAfterDelay {
    
	if (![self controlsHidden]) {
        [self cancelControlHiding];
		controlsVisibilityTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(hideControls) userInfo:nil repeats:NO];
	}
}

- (BOOL)controlsHidden {
    
    return [UIApplication sharedApplication].isStatusBarHidden;
}

- (void)hideControls {
    
    [self setControlsHidden:YES animated:YES permanent:NO];
}

- (void)toggleControls {
    
    [self setControlsHidden:![self controlsHidden] animated:YES permanent:NO];
}

@end
