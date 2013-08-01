//
//  ImageResizer.m
//  Commons-iOS
//
//  Created by Monte Hurd on 8/1/13.

#import "ImageResizer.h"

@implementation ImageResizer

-(void)createThumbImage
{
    NSFileManager *fm = [NSFileManager defaultManager];

    if (![fm fileExistsAtPath:self.thumbImagePath]) {
        if ([fm fileExistsAtPath:self.imagePath]) {

            UIImage *img = [UIImage imageWithContentsOfFile:self.imagePath];
            CGFloat hRatio = self.desiredSize.width / img.size.width;
            CGFloat vRatio = self.desiredSize.height / img.size.height;

            // Use MIN for UIViewContentModeScaleAspectFit
            float ratio = MIN(hRatio, vRatio);
            CGSize newSize = CGSizeMake(img.size.width * ratio, img.size.height * ratio);

            UIGraphicsBeginImageContext(newSize);
            [img drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
            UIImage *newImg = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();

            [UIImageJPEGRepresentation(newImg, 0.9f) writeToFile:self.thumbImagePath atomically:YES];
        }
    }
}

@end