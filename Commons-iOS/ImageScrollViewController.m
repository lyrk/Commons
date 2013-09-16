//
//  ImageScrollViewController.m
//  Commons-iOS
//
//  Created by Felix Mo on 2013-02-03.


#import "ImageScrollViewController.h"
#include <math.h>
#import <QuartzCore/QuartzCore.h>
#import "CommonsApp.h"
//#import "UIView+Debugging.h"

#define FULL_SCREEN_IMAGE_MIN_ZOOM_SCALE 0.5f
#define FULL_SCREEN_IMAGE_MAX_ZOOM_SCALE 5.0f

// Defines how dark the black overlay above the image can become when details slide up over the image
#define FULL_SCREEN_IMAGE_MAX_OVERLAY_ALPHA 0.8f

// Private
@interface ImageScrollViewController ()

@property (nonatomic) float initialScale;

@end

@implementation ImageScrollViewController{
    UIView *overlayView_;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.wantsFullScreenLayout = YES;
    }
    return self;
}

#pragma mark - Setters

- (void)setImage:(UIImage *)anImage {
    
    _image = anImage;
    
    [self.imageView setImage:_image];

    // Resize imageView to match new image size
    [self sizeImageViewToItsImage];
    
    // And zoom so image fits
    float scale = [self getScaleToMakeImageFullscreen];

    if (scale < self.imageScrollView.minimumZoomScale) {
        // Must adjust minimumZoomScale down or the image won't be able to be shrunken to fit
        self.imageScrollView.minimumZoomScale = scale * 0.5;
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
    f.size = self.image.size;
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
                                       (self.imageScrollView.contentSize.width/2) - (self.imageScrollView.bounds.size.width/2),
                                       (self.imageScrollView.contentSize.height/2) - (self.imageScrollView.bounds.size.height/2)
                                       );
    
    if(self.imageScrollView.bounds.size.width > self.imageScrollView.contentSize.width){
        centerOffset.x = 0;
    }
    if(self.imageScrollView.bounds.size.height > self.imageScrollView.contentSize.height){
        centerOffset.y = 0;
    }
    
    [self.imageScrollView setContentOffset:centerOffset animated:NO];
}

-(void)viewDidLayoutSubviews{
    [super viewWillLayoutSubviews];

    [self resetInitialZoomScaleAnimated:YES];
    [self centerScrollViewContents];
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
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[[CommonsApp singleton] getBackButtonString]
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:self
                                                                            action:@selector(backButtonPressed:)];

    [self setupOverlayView];
    
    [self setupImageScrollingViews];

    /*
     // Center activity indicator view
     CGRect bounds = [[UIScreen mainScreen] bounds];
    
     self.activityIndicator.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
     activityIndicator.autoresizingMask = (UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin);
    
     // Change the appearance of the status bar and navigation bar
     [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
     [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
     */
    
    // Setup UITapGestureRecognizers
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRight:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    
    // Add the gesture recognizers to the view
    [self.view addGestureRecognizer:swipeRight];

	// Don't make the view background clear or the space surrounding the image will
	// stop responding to touch events - perhaps because uiview's "hitTest:withEvent:"
	// doesn't fire if the touched view's alpha is < 0.01f?
    self.view.backgroundColor = [UIColor blackColor];
	
    [self.view setMultipleTouchEnabled:YES];
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

-(void)viewDidAppear:(BOOL)animated
{
    [self.view randomlyColorSubviews];
}
*/

#pragma mark - Image scrolling setup

-(void)setupImageScrollingViews
{
    /*
     Using autolayout with UIScrollView can be a bit confusing. See the following for basic information
     about the issue: 
     https://developer.apple.com/library/ios/technotes/tn2154/_index.html
     
     The following summary is also enlightening:
     "Constraints with scroll views work slightly differently than it does with other views.
     The constraints between of contentView and its superview (the scrollView) are to the scrollView's
     contentSize, not to its frame." From: http://stackoverflow.com/a/16843937
     */

    self.imageScrollView = [[UIScrollView alloc] init];
    self.imageScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageScrollView.delegate = self;
    self.imageScrollView.bouncesZoom = YES;
    self.imageScrollView.clipsToBounds = YES;
    self.imageScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.imageScrollView.showsHorizontalScrollIndicator = NO;
    self.imageScrollView.showsVerticalScrollIndicator = NO;
    self.imageScrollView.delaysContentTouches = NO;
    self.imageScrollView.contentMode = UIViewContentModeCenter;
    self.imageScrollView.minimumZoomScale = FULL_SCREEN_IMAGE_MIN_ZOOM_SCALE;
    self.imageScrollView.maximumZoomScale = FULL_SCREEN_IMAGE_MAX_ZOOM_SCALE;
    self.imageScrollView.zoomScale = 1.0f;
    self.imageScrollView.backgroundColor = [UIColor clearColor];

    [self.view addSubview:self.imageScrollView];

    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    contentView.backgroundColor = [UIColor clearColor];

    [self.imageScrollView addSubview:contentView];

    self.imageView = [[UIImageView alloc] init];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageView.backgroundColor = [UIColor clearColor];

    [contentView addSubview:self.imageView];

    NSDictionary *views = @{@"imageScrollView" : self.imageScrollView, @"contentView" : contentView, @"imageView" : self.imageView};

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageScrollView]|" options:0 metrics:0 views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageScrollView]|" options:0 metrics:0 views:views]];

    [self.imageScrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|" options:0 metrics:0 views:views]];
    [self.imageScrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[contentView]|" options:0 metrics:0 views:views]];
}

#pragma mark - UIScrollView

- (void)scrollViewDidZoom:(UIScrollView *)aScrollView {    
    // The scroll view has zoomed, so we need to re-center the contents
    [self centerScrollViewContents];
}

#pragma mark - UIScrollViewDelegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    
    return self.imageView;
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

-(BOOL)shouldAutorotate
{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutomaticallyForwardRotationMethods{
    return YES;
}

-(BOOL)shouldAutomaticallyForwardAppearanceMethods{
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

#pragma mark - Overlay view

-(void)setupOverlayView
{
    overlayView_ = [[UIView alloc] initWithFrame:self.view.bounds];
    overlayView_.translatesAutoresizingMaskIntoConstraints = NO;
    overlayView_.userInteractionEnabled = NO;
    overlayView_.backgroundColor = [UIColor clearColor];

    [self.view addSubview:overlayView_];

    NSDictionary *views = NSDictionaryOfVariableBindings(overlayView_);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[overlayView_]|" options:0 metrics:0 views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[overlayView_]|" options:0 metrics:0 views:views]];
}

-(void)clearOverlay
{
	overlayView_.backgroundColor = [UIColor clearColor];
}

@end
