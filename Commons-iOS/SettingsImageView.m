//
//  SettingsImageView.m
//  Commons-iOS
//
//  Created by Monte Hurd on 7/23/13.

#import "SettingsImageView.h"
#import "QuartzCore/QuartzCore.h"
//#import "LoginViewController.h"

@implementation SettingsImageView
{
    UIImage *unfilteredImage;
    UIImage *filteredImage;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {

        // Make the image from the storyboard immediately available as filtered. Nice as
        // it does the preparation of the filtered version on load. (A bit of memory is
        // used by the filtered version of course)
        [self prepareFilteredImage];

    }
    return self;
}

-(void) prepareFilteredImage
{
    // This readies the filtered version of the image. A call to "prepareFilteredImage"
    // was not placed in the "image" property setter - this is so more control can be
    // had over when the filtered version is made and is also why "prepareFilteredImage"
    // is public
    
    // Save the original image so "toUnfiltered" method may quickly restore it
    unfilteredImage = self.image;
    
    // Get reference to the image presently in use (presently this just uses the image from
    // the storyboard because it's happening in initWithCoder)
    CIImage *adjustedImage = [CIImage imageWithCGImage:self.image.CGImage];


    // Apply filters
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setValue: adjustedImage forKey:@"inputImage"];
    [blurFilter setValue: [NSNumber numberWithFloat:1.7f] forKey:@"inputRadius"];
    adjustedImage = [blurFilter outputImage];

    // Make a new core image filter for creating a black an white version of the image
    CIFilter *colorMonochrome = [CIFilter filterWithName:@"CIColorControls"];
    [colorMonochrome setValue: adjustedImage forKey: @"inputImage"];
    [colorMonochrome setValue: [NSNumber numberWithFloat:0.0f] forKey:@"inputSaturation"];
    [colorMonochrome setValue: [NSNumber numberWithFloat:-0.45f] forKey:@"inputBrightness"];
    [colorMonochrome setValue: [NSNumber numberWithFloat:0.2f] forKey:@"inputContrast"];
    adjustedImage = [colorMonochrome outputImage];

    // Save pointer to the filtered version so "toFiltered" method can quickly make use
    // of it

    //See: http://stackoverflow.com/a/15886422/135557
    CGImageRef imageRef = [[CIContext contextWithOptions:nil] createCGImage:adjustedImage fromRect:adjustedImage.extent];
    filteredImage = [UIImage imageWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
}

-(void) zoom
{
    [CATransaction begin];
    CABasicAnimation *zoom = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    zoom.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    zoom.toValue =   [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.06, 1.06, 1.0)];
    zoom.fillMode=kCAFillModeForwards;
    zoom.removedOnCompletion = NO;
    zoom.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    [CATransaction setCompletionBlock:^{
    }];
    [zoom setDuration:6.0];
    [self.layer addAnimation:zoom forKey:@"zoom"];
    [CATransaction commit];
}

-(void) toUnfiltered
{
    self.image = unfilteredImage;
}

-(void) toFiltered
{
    self.image = filteredImage;
}

@end
