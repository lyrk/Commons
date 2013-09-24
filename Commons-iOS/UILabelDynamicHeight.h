//
//  UIButtonDynamicHeight.h
//  Commons-iOS
//
//  Created by Monte Hurd on 9/16/13.

#import <UIKit/UIKit.h>

@interface UILabelDynamicHeight : UILabel

// Dynamic height label with adjustable padding and borders. Adjusts its size
// automatically to encompass text changes and plays nice with constraints. All
// changes animatable.

// Note: Don't add a height constraint. One will be dynamically maintained varying
// with the height (plus padding) of whatever text the button's label is showing.

// Allows individual settings for each edge's border and padding.

// The border insets property is most useful when using solid colors for the
// label backgroundColor, paddingColor and borderColor. When using partially
// transparent colors they may not produce the exact result you want - ie
// the borderView is behind the paddingView and both of these are behind this
// label's view:
//     *you looking down*
//             |
//             V
//          -------    <--label view    (UILabel's default view)
//          -------    <--paddingView   (added and maintained by this obj)
//          -------    <--borderView    (added and maintained by this obj)
//
// This means a partially transparent label view will see some of the color
// from the padding view, and the same is true for the padding view if it is
// partially transparent (the border view will show through). This is not a
// concern if solid colors are being used, but if not it can produce unwanted
// results. To get around this, if needed, the paddingView and borderView
// (which this object creates) are accessable. The are read-only, but this
// just means you can't swap them out, their *properties* may still be set.
// So, to say, set a solid color border which doesn't bleed up through the
// padding and label views, simply prepare a suitably sized borderView by setting
// borderInsets, then set the border view's backing layer's border via quartz:
//      myLabel.borderInsets = UIEdgeInsetsMake(3.0, 3.0, 3.0, 3.0);
//      myLabel.borderView.layer.borderSize = 3.0f;
//      myLabel.borderView.layer.borderColor = [UIColor redColor].CGColor;

// Convenience property for setting borderView's background color
@property (strong, nonatomic) UIColor *borderColor;

// Allows individual settings for each edge's border
@property (nonatomic) UIEdgeInsets borderInsets;

// Convenience property for setting paddingView's background color
@property (strong, nonatomic) UIColor *paddingColor;

// Allows individual settings for each edge's padding
@property (nonatomic) UIEdgeInsets paddingInsets;

// Read-only access to the padding and border views which the object creates.
// Allows for fine tuning things like rounded corners.
@property (strong, nonatomic, readonly) UIView *paddingView;
@property (strong, nonatomic, readonly) UIView *borderView;

// Sets random text, border and padding
// Call debug when the label is tapped to see its settings randomized
// and animated to their new values.
-(void)debug;

@end
