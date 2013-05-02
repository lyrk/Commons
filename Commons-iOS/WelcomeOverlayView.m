//
//  WelcomeOverlayView.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/1/13.

#import "WelcomeOverlayView.h"
#import "MWI18N/MWMessage.h"

@implementation WelcomeOverlayView{
    WelcomeMessage message;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.hidden = YES;
        self.interfaceOrientation = UIDeviceOrientationPortrait;
        message = NONE;
    }
    return self;
}

-(void) showMessage:(WelcomeMessage) msg
{
    switch (msg) {
        case WELCOME:
            // "No Images Found..." message
            self.messageLabel.text = [MWMessage forKey:@"welcome-no-images-message"].text;
            self.hidden = NO;
            break;
        case CHOOSE_OR_TAKE:
            // "Take or Choose a Photo" message
            self.messageLabel.text = [MWMessage forKey:@"welcome-take-or-choose-message"].text;
            self.hidden = NO;
            break;
        default:
            self.hidden = YES;
            break;
    }
    message = msg;
    
    // Force the drawing code to redraw
    [self setNeedsDisplay];
}

// Used to make smaller line segments
float lerp(float v0, float v1, float t)
{
    return v0 + (v1 - v0) * t;
}

- (void)drawRect:(CGRect)rect
{   // Draw faint lines between the message label and the add media, choose and take photo buttons
    
    [super drawRect:rect];
    
    // If no message is being shown there's no need to draw anything
    if (message == NONE) return;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:0.5].CGColor);
    CGContextSetLineWidth(context, 1.0);
    
    // Block for drawing lines between the message label and the buttons
    void(^drawLerpLine)(CGPoint startPoint, CGPoint endPoint, float startOffset, float endOffset) = ^(CGPoint startPoint, CGPoint endPoint, float startOffset, float endOffset){
        
        CGPoint lerpedStart = CGPointMake(lerp(endPoint.x, startPoint.x, endOffset), lerp(endPoint.y, startPoint.y, endOffset));
        CGPoint lerpedEnd = CGPointMake(lerp(startPoint.x, endPoint.x, startOffset), lerp(startPoint.y, endPoint.y, startOffset));
        
        CGContextMoveToPoint(context, lerpedStart.x, lerpedStart.y);
        CGContextAddLineToPoint(context, lerpedEnd.x, lerpedEnd.y);
        CGContextStrokePath(context);
    };
    
    // These determine how far from the line start and end points the drawing will begin and end
    float startReduction = 0.0;
    float endReduction = 0.0;
    
    if (message == WELCOME) {
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
        drawLerpLine(self.messageLabel.center, self.addMediaButton.center, startReduction, endReduction);
        
    }else if (message == CHOOSE_OR_TAKE) {
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
        drawLerpLine(self.messageLabel.center, self.takePhotoButton.center, startReduction, endReduction);
        drawLerpLine(self.messageLabel.center, self.choosePhotoButton.center, startReduction, endReduction);
    }
}

@end
