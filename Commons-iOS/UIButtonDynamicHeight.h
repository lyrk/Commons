//
//  UIButtonDynamicHeight.h
//  Commons-iOS
//
//  Created by Monte Hurd on 9/16/13.

#import <UIKit/UIKit.h>

@interface UIButtonDynamicHeight : UIButton

// Don't add a height constraint! One will be dynamically maintained varying
// with the height (plus padding) of whatever text the button's label is showing.
@property (strong, nonatomic) NSNumber *padding;

@end
