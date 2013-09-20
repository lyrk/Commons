//
//  UIButtonDynamicHeight.m
//  Commons-iOS
//
//  Created by Monte Hurd on 9/16/13.

#import "UIButtonDynamicHeight.h"
#import <QuartzCore/QuartzCore.h>

@interface UIButtonDynamicHeight()

@property (strong, nonatomic) NSLayoutConstraint *heightConstraint;

@end

@implementation UIButtonDynamicHeight

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
        self.padding = @0.0f;
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        // Constraint for button height. Used to vary button height based on text height
        self.heightConstraint = [NSLayoutConstraint constraintWithItem:self
                                                             attribute:NSLayoutAttributeHeight
                                                             relatedBy:0
                                                                toItem:nil
                                                             attribute:NSLayoutAttributeNotAnAttribute
                                                            multiplier:1
                                                              constant:self.frame.size.height];
        [self addConstraint:self.heightConstraint];
        
        // Constraint for ensuring button's internal title label remains centered
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:0
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1
                                                          constant:0]];

        void(^observe)(NSObject *, NSString *) = ^(NSObject *obj, NSString *str){
            [obj addObserver:self forKeyPath:str options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
        };

        // Observe the button's label frame so the button itself can be resized
        // to accomodate whatever height the label text needs (plus padding)
        observe(self.titleLabel, @"frame");

        // If the padding value is changed update the button as well
        observe(self, @"padding");
}

-(void)dealloc
{
	[self.titleLabel removeObserver:self forKeyPath:@"frame"];
	[self removeObserver:self forKeyPath:@"padding"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"frame"] || [keyPath isEqualToString:@"padding"]) {
        NSValue *new = [change valueForKey:@"new"];
        NSValue *old = [change valueForKey:@"old"];
        if (new && old) {
            if (![old isEqualToValue:new]) {
                // Get value for padding between the text and the button edges
                float padding = self.padding.floatValue;

                self.titleEdgeInsets = UIEdgeInsetsMake(padding, padding, padding, padding);
                
                // Wrap the button's label text at the button's present width constraint minus the padding.
                // (Controls the button's internal title label width.)
                self.titleLabel.preferredMaxLayoutWidth = self.frame.size.width - (padding * 2);
                
                // Adjust button height to accomodate new text height plus padding
                self.heightConstraint.constant = [new CGRectValue].size.height + (padding * 2);
            }
        }
    }
}

@end
