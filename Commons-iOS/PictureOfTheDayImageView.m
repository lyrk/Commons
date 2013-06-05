//
//  PictureOfTheDayImageView.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/30/13.

#import "PictureOfTheDayImageView.h"

@implementation PictureOfTheDayImageView
{
    UIImage *pictureOfTheDayImage;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.useFilter = NO;
    }
    return self;
}

- (void)setImage:(UIImage *)inImage
{
    if (!self.useFilter) {
        [super setImage:inImage];
        return;
    }

    CIImage *adjustedImage = [CIImage imageWithCGImage:inImage.CGImage];

    // Apply a Core Image filter
    CIFilter *colorMonochrome = [CIFilter filterWithName:@"CIColorMonochrome"];
    [colorMonochrome setDefaults];
    [colorMonochrome setValue: adjustedImage forKey: @"inputImage"];
    [colorMonochrome setValue: [CIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f] forKey: @"inputColor"];
    adjustedImage = [colorMonochrome outputImage];

    /*
    //Could easily add another filter. Example:
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setValue: adjustedImage forKey:@"inputImage"];
    [blurFilter setDefaults];
    [blurFilter setValue: [NSNumber numberWithFloat:1.7f] forKey:@"inputRadius"];
    adjustedImage = [blurFilter outputImage];
    */
    
    //See: http://stackoverflow.com/a/15886422/135557
    CGImageRef imageRef = [[CIContext contextWithOptions:nil] createCGImage:adjustedImage fromRect:adjustedImage.extent];
    UIImage *outputImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    [super setImage:outputImage];
}

@end
