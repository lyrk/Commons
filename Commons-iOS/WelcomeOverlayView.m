//
//  WelcomeOverlayView.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/1/13.

#import "WelcomeOverlayView.h"
#import "MWI18N/MWMessage.h"
#import <QuartzCore/QuartzCore.h>

@implementation WelcomeOverlayView
{
    WelcomeMessage message;
    CAShapeLayer *lineLayerTake;
    CAShapeLayer *lineLayerGallery;
    CAShapeLayer *lineLayerAdd;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.hidden = YES;
        self.interfaceOrientation = UIDeviceOrientationPortrait;
        message = WELCOME_MESSAGE_NONE;
        
        lineLayerTake = [CAShapeLayer layer];
        lineLayerGallery = [CAShapeLayer layer];
        lineLayerAdd = [CAShapeLayer layer];
    }
    return self;
}

-(void) showMessage:(WelcomeMessage) msg
{
    // Make the message fade in, but only do so if a different message is to be shown
    // otherwise it flickers
    if (message != msg) self.messageLabel.alpha = 0.0;
    
    switch (msg) {
        case WELCOME_MESSAGE_WELCOME:
            // "No Uploads Found..." message
            self.messageLabel.text = [MWMessage forKey:@"welcome-no-images-message"].text;
            self.hidden = NO;
            break;
        case WELCOME_MESSAGE_CHOOSE_OR_TAKE:
            // "Take or Choose a Photo" message
            self.messageLabel.text = [MWMessage forKey:@"welcome-take-or-choose-message"].text;
            self.hidden = NO;
            break;
        case WELCOME_MESSAGE_CHECKING:
            // "Checking for Previous Uploads" message
            self.messageLabel.text = [MWMessage forKey:@"welcome-checking-message"].text;
            self.hidden = NO;
            break;
        default:
            self.hidden = YES;
            break;
    }
    
    // Fade in the message
    if (message != msg) {
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:UIViewAnimationOptionTransitionNone
                         animations:^{
                             self.messageLabel.alpha = 1.0;
                         }
                         completion:^(BOOL finished){
                         }];
    }
    
    message = msg;
    
    // Animate the drawing of the lines
    [self animateLines];
}

// Used to make smaller line segments
float lerp(float v0, float v1, float t)
{
    return v0 + (v1 - v0) * t;
}

-(void)animateLines
{   // Draw dashed lines from the messageLabel to the buttons using core animation to make the lines grow
    // from the messageLabel in the direction of the respective button
    
    // If no message is being shown there's no need to draw anything
    if ((message == WELCOME_MESSAGE_NONE) || (message == WELCOME_MESSAGE_CHECKING)) return;

    // Block for drawing lines between the message label and the buttons
    void(^drawLerpLine)(CAShapeLayer *pathLayer, CGPoint startPoint, CGPoint endPoint, float startOffset, float endOffset) = ^(CAShapeLayer *pathLayer, CGPoint startPoint, CGPoint endPoint, float startOffset, float endOffset){
        
        CGPoint lerpedStart = CGPointMake(lerp(endPoint.x, startPoint.x, endOffset), lerp(endPoint.y, startPoint.y, endOffset));
        CGPoint lerpedEnd = CGPointMake(lerp(startPoint.x, endPoint.x, startOffset), lerp(startPoint.y, endPoint.y, startOffset));

        // Determine if the line about to be drawn is already onscreen
        if (pathLayer.path != nil) {
            // Check for both points
            if(
               (CGPathContainsPoint(pathLayer.path, nil, lerpedStart, false))
                    &&
               (CGPathContainsPoint(pathLayer.path, nil, lerpedEnd, false))
            ){
                // Check layer presense (determines whether the pathLayer actually on-screen)
                if(NSNotFound != [self.layer.sublayers indexOfObject:pathLayer]) {
                    // The line already exists, so don't redraw
                    return;
                }
            }
        }

        // Safe to animate drawing of the line
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:lerpedEnd];
        [path addLineToPoint:lerpedStart];
        
        pathLayer.frame = self.bounds;
        pathLayer.path = path.CGPath;
        pathLayer.strokeColor = [[UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.5] CGColor];
        pathLayer.fillColor = nil;
        pathLayer.lineJoin = kCALineJoinBevel;
        pathLayer.lineWidth = 2.0f;
        [pathLayer setLineDashPattern:@[@4, @4]];

        [self.layer addSublayer:pathLayer];

        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        pathAnimation.duration = 0.35;
        pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
        pathAnimation.toValue = [NSNumber numberWithFloat:1.0f];
        
        [pathLayer removeAllAnimations];
        [pathLayer addAnimation:pathAnimation forKey:@"strokeEnd"];
    };
    
    // These determine how far from the line start and end points the drawing will begin and end
    float startReduction = 0.0;
    float endReduction = 0.0;
    
    if (message == WELCOME_MESSAGE_WELCOME) {
        // Draw single line between the message label and the add media button
        
        // Landscape
        if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation)){
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
                startReduction = 0.24;
                endReduction = 0.23;
            }else{
                startReduction = 0.42;
                endReduction = 0.47;
            }
            
            // Portrait
        }else{
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
                startReduction = 0.25;
                endReduction = 0.25;
            }else{
                startReduction = 0.29;
                endReduction = 0.29;
            }
        }
        // Hide the lines to the choose and take picture buttons
        [lineLayerTake removeFromSuperlayer];
        [lineLayerGallery removeFromSuperlayer];
        // Show the line to the add image button
        drawLerpLine(lineLayerAdd, self.messageLabel.center, self.addMediaButton.center, startReduction, endReduction);
        
    }else if (message == WELCOME_MESSAGE_CHOOSE_OR_TAKE) {
        // Draw lines between the message label and take and choose photo buttons
        
        // Landscape
        if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation)){
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
                startReduction = 0.28;
                endReduction = 0.25;
            }else{
                startReduction = 0.65;
                endReduction = 0.25;
            }
            
            // Portrait
        }else{
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
                startReduction = 0.28;
                endReduction = 0.25;
            }else{
                startReduction = 0.25;
                endReduction = 0.27;
            }
        }
        // Hide the line to the add image button
        [lineLayerAdd removeFromSuperlayer];
        // Show the lines to the choose and take picture buttons
        drawLerpLine(lineLayerTake, self.messageLabel.center, self.takePhotoButton.center, startReduction, endReduction);
        drawLerpLine(lineLayerGallery, self.messageLabel.center, self.choosePhotoButton.center, startReduction, endReduction);
    }
}

-(void) clearLines
{   // Easy reset of all lines
    lineLayerAdd.path = nil;
    lineLayerTake.path = nil;
    lineLayerGallery.path = nil;
    [lineLayerAdd removeFromSuperlayer];
    [lineLayerTake removeFromSuperlayer];
    [lineLayerGallery removeFromSuperlayer];
}

@end
