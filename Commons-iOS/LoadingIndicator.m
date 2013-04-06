//
//  LoadingIndicator.m
//  Commons-iOS
//
//  Created by MONTE HURD on 4/6/13.
//

#import "LoadingIndicator.h"
//#import "AppDelegate.h"

@interface LoadingIndicator()

@end

@implementation LoadingIndicator{
	CGPoint origCenter;
	CGRect origFrame;
	UIActivityIndicatorViewStyle origUIActivityIndicatorViewStyle;
}

#pragma mark -
#pragma mark INIT/DEALLOC

-(id)initWithFrame:(CGRect)frame{     // sizes the view according to the style
	if((self = [super initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge])) {

		self.color = [UIColor blackColor];
	
		CGPoint activityIndicatorLocation = CGPointMake(frame.size.width/2, frame.size.height/2);
		
		self.center = activityIndicatorLocation;
		self.hidden = YES;
				
		// Save off orig size/position/style in case we change any of these before showing (will restore them upon hide)
		origCenter = self.center;
		origFrame = self.frame;
		origUIActivityIndicatorViewStyle = self.activityIndicatorViewStyle;		
	}
	return self;
}

-(void)show{	
	// For some reason it's getting reset so force it here for now
	self.activityIndicatorViewStyle	= UIActivityIndicatorViewStyleWhiteLarge;
	self.color = [UIColor blackColor];

	// Make the loading indicator block touch events
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	// Make sure the indicator isn't covered up!
	[self.superview bringSubviewToFront:self];
		
	self.hidden = NO;
	[self startAnimating];
}

-(void)hide{
	// Make the loading indicator no longer block touch events
	[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	
	self.hidden = YES;
	[self stopAnimating];
	
	self.center = origCenter;
	self.frame = origFrame;
	self.activityIndicatorViewStyle = origUIActivityIndicatorViewStyle;
}

@end

