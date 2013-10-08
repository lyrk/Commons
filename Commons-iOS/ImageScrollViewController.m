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

#define FULL_SCREEN_IMAGE_MIN_ZOOM_SCALE 0.1f
#define FULL_SCREEN_IMAGE_MAX_ZOOM_SCALE 5.0f

// Defines how dark the black overlay above the image can become when details slide up over the image
#define FULL_SCREEN_IMAGE_MAX_OVERLAY_ALPHA 0.8f

@interface ImageScrollViewController ()

@property (nonatomic, strong) UIImage *imageInternal;

@end

@implementation ImageScrollViewController{
    UIView *overlayView_;
}

#pragma mark - Setters

- (void)setImageInternal:(UIImage *)anImage {
    
    _imageInternal = anImage;
    
    [self.imageView setImage:_imageInternal];

    // Resize imageView to match new image size
    [self.imageView sizeToFit];
    
    // And zoom so image fits
    float scale = [self getScaleToMakeImageFullscreen];

    if (scale < self.imageScrollView.minimumZoomScale) {
        // Must adjust minimumZoomScale down or the image won't be able to be shrunken to fit
        self.imageScrollView.minimumZoomScale = scale * 0.5;
    }

    [self.imageScrollView setZoomScale:scale animated:NO];
}

#pragma mark - Positioning

-(float)getScaleToMakeImageFullscreen
{
    // Determine the scale adjustment required to make the imageView fit completely within the view
    // (Note: this works because the imageView is sized to its image's size when its image is changed)
    CGSize dst = self.view.bounds.size;
    CGSize src = self.imageView.image.size;
    float scale = fminf(dst.width / src.width, dst.height / src.height);
    return scale;
}

- (void)centerScrollViewContents {
    CGSize contentSize = self.imageScrollView.contentSize;
    CGSize scrollViewSize = self.imageScrollView.bounds.size;
    
    CGFloat offsetX = (scrollViewSize.width > contentSize.width)?
    (scrollViewSize.width - contentSize.width) * 0.5 : 0.0;
    
    CGFloat offsetY = (scrollViewSize.height > contentSize.height)?
    (scrollViewSize.height - contentSize.height) * 0.5 : 0.0;
    
    self.imageView.center = CGPointMake(
        (contentSize.width * 0.5) + offsetX,
        (contentSize.height * 0.5) + offsetY
    );
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    [self centerScrollViewContents];
    //[self.view randomlyColorSubviews];
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

    // For iOS 6 so it considers the absolute top left of the screen to be 0,0 - otherwise just below the
    // title bar is 0,0
    self.wantsFullScreenLayout = YES;

    // Change back button to be an arrow
    self.navigationItem.leftBarButtonItem = [[CommonsApp singleton] getBackButtonItemWithTarget:self action:@selector(backButtonPressed:)];

    [self setupOverlayView];
    
    [self setupImageScrollingViews];
    
	// Don't make the view background clear or the space surrounding the image will
	// stop responding to touch events - perhaps because uiview's "hitTest:withEvent:"
	// doesn't fire if the touched view's alpha is < 0.01f?
    self.view.backgroundColor = [UIColor blackColor];
	
    [self.view setMultipleTouchEnabled:YES];

    //[self.view randomlyColorSubviews];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    // Ensure the image, if pinch-expanded, doesn't overlap the My Uploads view when this view is popped
    self.imageScrollView.clipsToBounds = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Setting imageInternal was delayed until the view is about to appear so the view
    // controller has a chance to finish loading / setting up its subviews. Otherwise
    // code which positions the layout of the image happens too soon (before self.view's
    // dimensions have been established / made available).
    self.imageInternal = self.image;

    self.imageScrollView.clipsToBounds = NO;
    /*
        if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
            // Make self.view's top not underlap the nav bar. By doing this and having
            // the scrollView *not* clip to bounds the scroll view will load so its
            // top is just below the nav bar's bottom, yet scrolling will still allow
            // content to visually scroll up and under the nav bar (thanks to not clipping)
            self.edgesForExtendedLayout = UIRectEdgeNone;
        }
    */
}

/*
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
    // Not clipping bounds means the scroll view can underlap the nav bar even if edgesForExtendedLayout is UIRectEdgeNone
    self.imageScrollView.clipsToBounds = NO;
    self.imageScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.imageScrollView.showsHorizontalScrollIndicator = NO;
    self.imageScrollView.showsVerticalScrollIndicator = NO;
    self.imageScrollView.delaysContentTouches = NO;
    self.imageScrollView.contentMode = UIViewContentModeCenter;
    self.imageScrollView.minimumZoomScale = FULL_SCREEN_IMAGE_MIN_ZOOM_SCALE;
    self.imageScrollView.maximumZoomScale = FULL_SCREEN_IMAGE_MAX_ZOOM_SCALE;
    self.imageScrollView.zoomScale = 1.0f;
    self.imageScrollView.backgroundColor = [UIColor blackColor];

    [self.view addSubview:self.imageScrollView];

    // The imageView is sized based on the size of the image it is displaying (see "sizeToFit")
    // So no constraints on its size!
    self.imageView = [[UIImageView alloc] init];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageView.backgroundColor = [UIColor clearColor];

    NSDictionary *views = @{@"imageScrollView" : self.imageScrollView, @"imageView" : self.imageView};

    // Make the scrollView hug self.view
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageScrollView]|" options:0 metrics:0 views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageScrollView]|" options:0 metrics:0 views:views]];

    [self.imageScrollView addSubview:self.imageView];
}

#pragma mark - UIScrollView

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    // The scroll view has zoomed, so we need to re-center the contents
    [self centerScrollViewContents];
}

#pragma mark - UIScrollViewDelegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
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
