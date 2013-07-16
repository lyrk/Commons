//
//  WelcomeOverlayView.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/1/13.

#import "WelcomeOverlayView.h"
#import "MWI18N/MWMessage.h"
#import <QuartzCore/QuartzCore.h>
#import "CALerpLine.h"

@implementation WelcomeOverlayView
{
    WelcomeMessage message_;
    CAShapeLayer *lineLayerTake_;
    CAShapeLayer *lineLayerGallery_;
    CAShapeLayer *lineLayerAdd_;
    CALerpLine *lerpLine_;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {

        self.hidden = YES;
        self.interfaceOrientation = UIDeviceOrientationPortrait;
        message_ = WELCOME_MESSAGE_NONE;

        lerpLine_ = [[CALerpLine alloc] init];
        lineLayerTake_ = [CAShapeLayer layer];
        lineLayerGallery_ = [CAShapeLayer layer];
        lineLayerAdd_ = [CAShapeLayer layer];
    }
    return self;
}

-(void) showMessage:(WelcomeMessage) msg
{
    // Make the message fade in, but only do so if a different message is to be shown
    // otherwise it flickers
    if (message_ != msg) self.messageLabel.alpha = 0.0;
    
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
    if (message_ != msg) {
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:UIViewAnimationOptionTransitionNone
                         animations:^{
                             self.messageLabel.alpha = 1.0;
                         }
                         completion:^(BOOL finished){
                         }];
    }
    
    message_ = msg;
    
    // Animate the drawing of the lines
    [self animateLines];
}

-(void)animateLines
{   // Draw dashed lines from the messageLabel to the buttons using core animation to make the lines grow
    // from the messageLabel in the direction of the respective button
    
    // If no message is being shown there's no need to draw anything
    if ((message_ == WELCOME_MESSAGE_NONE) || (message_ == WELCOME_MESSAGE_CHECKING)) return;
    
    // Block for drawing lines between the message label and the buttons - nice place for common settings
    void(^drawLerpLine)(CAShapeLayer *, CGPoint, float, float) = ^(CAShapeLayer *pathLayer, CGPoint endPoint, float startOffset, float endOffset){
        lerpLine_.view = self;
        lerpLine_.pathLayer = pathLayer;
        lerpLine_.startPoint = self.messageLabel.center;
        lerpLine_.endPoint = endPoint;
        lerpLine_.startOffset = startOffset;
        lerpLine_.endOffset = endOffset;
        lerpLine_.duration = 0.35;
        lerpLine_.from = 0.0;
        lerpLine_.to = 1.0;
        lerpLine_.strokeColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.5];
        lerpLine_.lineWidth = 2.0f;
        lerpLine_.lineDashPattern = @[@4, @4];
        [lerpLine_ drawLine];
    };

    // These determine how far from the line start and end points the drawing will begin and end
    float startReduction = 0.0;
    float endReduction = 0.0;
    
    if (message_ == WELCOME_MESSAGE_WELCOME) {
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
        [lineLayerTake_ removeFromSuperlayer];
        [lineLayerGallery_ removeFromSuperlayer];
        // Show the line to the add image button
        drawLerpLine(lineLayerAdd_, self.addMediaButton.center, startReduction, endReduction);
        
    }else if (message_ == WELCOME_MESSAGE_CHOOSE_OR_TAKE) {
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
        [lineLayerAdd_ removeFromSuperlayer];
        // Show the lines to the choose and take picture buttons
        drawLerpLine(lineLayerTake_, self.takePhotoButton.center, startReduction, endReduction);
        drawLerpLine(lineLayerGallery_, self.choosePhotoButton.center, startReduction, endReduction);
    }
}

-(void) clearLines
{   // Easy reset of all lines
    lineLayerAdd_.path = nil;
    lineLayerTake_.path = nil;
    lineLayerGallery_.path = nil;
    [lineLayerAdd_ removeFromSuperlayer];
    [lineLayerTake_ removeFromSuperlayer];
    [lineLayerGallery_ removeFromSuperlayer];
}

@end
