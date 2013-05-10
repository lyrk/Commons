//
//  LoadingIndicator.h
//  Commons-iOS
//
//  Created by MONTE HURD on 4/6/13.
//

// Used to easily display/hide round (touch blocking) UIActivityIndicatorView spinning wheel
// to indicate loading

@interface LoadingIndicator : UIActivityIndicatorView {

}

@property (weak, nonatomic) UIWindow *window;

-(void)show;
-(void)hide;

@end
