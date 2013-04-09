//
//  GrayscaleImageView.h
//  Commons-iOS
//
//  Created by Monte Hurd on 4/8/13.

#import <UIKit/UIKit.h>

/*
 Class for making UIImageView able to toggle between color and greyscale version of the image being displayed.
 If showing an image set in the storyboard the "toColor" and "toGrayscale" methods are immediately available.
 If showing an image which was set via code the "prepareGrayscaleImage" method must be called once before the
  "toColor" and "toGrayscale" methods will work
*/

@interface GrayscaleImageView : UIImageView

-(void) toColor;
-(void) toGrayscale;
-(void) prepareGrayscaleImage;

@end
