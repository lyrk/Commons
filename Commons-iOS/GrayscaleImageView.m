//
//  GrayscaleImageView.m
//  Commons-iOS
//
//  Created by Monte Hurd on 4/8/13.

#import "GrayscaleImageView.h"

@implementation GrayscaleImageView
{
    UIImage *colorImage;
    UIImage *grayscaleImage;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {

        // Make the image from the storyboard immediately available as greyscale. Nice as
        // it does the preparation of the grayscale version on load. (A bit of memory is
        // used by the grayscale version of course)
        [self prepareGrayscaleImage];

    }
    return self;
}

-(void) prepareGrayscaleImage
{
    // This readies the grayscale version of the image. A call to "prepareGrayscaleImage"
    // was not placed in the "image" property setter - this is so more control can be
    // had over when the grayscale version is made and is also why "prepareGrayscaleImage"
    // is public
    
    // Save the original image so "toColor" method may quickly restore it
    colorImage = self.image;
    
    // Get reference to the image presently in use (presently this just uses the image from
    // the storyboard because it's happening in initWithCoder)
    CIImage *adjustedImage = [CIImage imageWithCGImage:self.image.CGImage];
    
    // Make a new core image filter for creating a black an white version of the image
    CIFilter *colorMonochrome = [CIFilter filterWithName:@"CIColorMonochrome"];
    [colorMonochrome setDefaults];
    [colorMonochrome setValue: adjustedImage forKey: @"inputImage"];
    [colorMonochrome setValue: [CIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f] forKey: @"inputColor"];
    adjustedImage = [colorMonochrome outputImage];

    /* Could easily add another filter. Example:
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setValue: adjustedImage forKey:@"inputImage"];
    [blurFilter setDefaults];
    [blurFilter setValue: [NSNumber numberWithFloat:1.7f] forKey:@"inputRadius"];
    adjustedImage = [blurFilter outputImage];
    */
    
    // Save pointer to the grayscale version so "toGrayscale" method can quickly make use
    // of it
    grayscaleImage = [[UIImage alloc] initWithCIImage: adjustedImage];
}

-(void) toColor
{
    self.image = colorImage;
}

-(void) toGrayscale
{
    self.image = grayscaleImage;
}

@end
