//
//  LoadingIndicator.m
//  Commons-iOS
//
//  Created by MONTE HURD on 4/6/13.
//

#import "LoadingIndicator.h"
#import "CommonsApp.h"
#import <QuartzCore/QuartzCore.h>

@interface LoadingIndicator()

@end

@implementation LoadingIndicator{
	CGPoint origCenter;
	UIActivityIndicatorViewStyle origUIActivityIndicatorViewStyle;
    UIView *opaqueView;
    UIView *backgroundView;
}

#pragma mark -
#pragma mark INIT/DEALLOC

-(id)initWithFrame:(CGRect)frame{     // sizes the view according to the style
	if((self = [super initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge])) {

		self.color = [UIColor lightGrayColor];
	
		CGPoint activityIndicatorLocation = CGPointMake(frame.size.width/2, frame.size.height/2);
		
		self.center = activityIndicatorLocation;
		self.hidden = YES;
				
		// Save off orig size/position/style in case we change any of these before showing (will restore them upon hide)
		origCenter = self.center;
		origUIActivityIndicatorViewStyle = self.activityIndicatorViewStyle;
	}
	return self;
}

-(void)show{	
	// For some reason it's getting reset so force it here for now
	self.activityIndicatorViewStyle	= UIActivityIndicatorViewStyleWhiteLarge;
	self.color = [UIColor lightGrayColor];

    // Make the loading indicator block touch events using a mostly transparent view
    // (created here each time so it accounts for present screen dimensions)
    opaqueView = [[UIView alloc] initWithFrame:self.window.bounds];
    opaqueView.userInteractionEnabled = YES; // "YES" so touches terminate with it

    opaqueView.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.25];
    [self.window addSubview:opaqueView];
    
    // Move the opaque view in front of everything except the spinner
    [opaqueView.superview bringSubviewToFront:opaqueView];

    // Add a small rounded-corner view behind the spinner for contrast
    backgroundView = [[UIView alloc] initWithFrame:(CGRect){0.0f, 0.0f, 85.0f, 85.0f}];
    backgroundView.userInteractionEnabled = NO;
    backgroundView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.7f];
    backgroundView.center = self.center;
    [[CommonsApp singleton] roundCorners:UIRectCornerAllCorners ofView:backgroundView toRadius:10.0];

    [self.window addSubview:backgroundView];
    [backgroundView.superview bringSubviewToFront:backgroundView];

	// Make sure the spinning indicator isn't covered up!
	[self.superview bringSubviewToFront:self];
		
	self.hidden = NO;
	[self startAnimating];
}

-(void)hide{
	// Make the loading indicator no longer block touch events
    [opaqueView removeFromSuperview];
    [backgroundView removeFromSuperview];

	self.hidden = YES;
	[self stopAnimating];
	
	self.center = origCenter;
	self.activityIndicatorViewStyle = origUIActivityIndicatorViewStyle;
}

@end

