//
//  SettingsImageView.h
//  Commons-iOS
//
//  Created by Monte Hurd on 7/23/13.

#import <UIKit/UIKit.h>

/*
 Class for making UIImageView able to toggle between filtered and unfiltered version of the image being displayed.
 If showing an image set in the storyboard the "toUnfiltered" and "toFiltered" methods are immediately available.
 If showing an image which was set via code the "prepareFilteredImage" method must be called once before the
  "toUnfiltered" and "toFiltered" methods will work
*/

@interface SettingsImageView : UIImageView

-(void) toUnfiltered;
-(void) toFiltered;
-(void) prepareFilteredImage;
-(void) zoom;

@end
