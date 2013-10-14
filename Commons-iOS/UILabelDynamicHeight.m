//
//  UIButtonDynamicHeight.m
//  Commons-iOS
//
//  Created by Monte Hurd on 9/16/13.

#import "UILabelDynamicHeight.h"

@implementation UILabelDynamicHeight{

NSLayoutConstraint *borderConstraintTop_;
NSLayoutConstraint *borderConstraintBottom_;
NSLayoutConstraint *borderConstraintLeft_;
NSLayoutConstraint *borderConstraintRight_;

NSLayoutConstraint *paddingConstraintTop_;
NSLayoutConstraint *paddingConstraintBottom_;
NSLayoutConstraint *paddingConstraintLeft_;
NSLayoutConstraint *paddingConstraintRight_;

}

#pragma mark - Build! destroy!

- (id)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

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

-(void)setup
{
    borderConstraintTop_ = nil;
    borderConstraintBottom_ = nil;
    borderConstraintLeft_ = nil;
    borderConstraintRight_ = nil;

    paddingConstraintTop_ = nil;
    paddingConstraintBottom_ = nil;
    paddingConstraintLeft_ = nil;
    paddingConstraintRight_ = nil;

    // numberOfLines = 0 means allow as many lines as needed for whatever width constraint is being used
    self.numberOfLines = 0;
    // clipsToBounds = YES allows for rounded corners on self.layer
    self.clipsToBounds = YES;

    _paddingView = nil;
    _borderView = nil;

    _paddingInsets = UIEdgeInsetsZero;
    _borderInsets = UIEdgeInsetsZero;

    _paddingColor = [UIColor blackColor];
    _borderColor = [UIColor whiteColor];

    _paddingView = [[UIView alloc] init];
    self.paddingView.translatesAutoresizingMaskIntoConstraints = NO;
    self.paddingView.backgroundColor = [UIColor redColor];

    _borderView = [[UIView alloc] init];
    self.borderView.translatesAutoresizingMaskIntoConstraints = NO;
    self.borderView.backgroundColor = [UIColor greenColor];
    
    self.userInteractionEnabled = YES;
}

-(void)dealloc
{
    [self.superview removeConstraint:paddingConstraintTop_];
    [self.superview removeConstraint:paddingConstraintBottom_];
    [self.superview removeConstraint:paddingConstraintLeft_];
    [self.superview removeConstraint:paddingConstraintRight_];
    
    [self.superview removeConstraint:borderConstraintTop_];
    [self.superview removeConstraint:borderConstraintBottom_];
    [self.superview removeConstraint:borderConstraintLeft_];
    [self.superview removeConstraint:borderConstraintRight_];

    [self.paddingView removeFromSuperview];
    [self.borderView removeFromSuperview];
}

#pragma mark - Getters / setters

-(void)setBorderInsets:(UIEdgeInsets)borderInsets
{
    if (!UIEdgeInsetsEqualToEdgeInsets(_borderInsets, borderInsets)) {
        _borderInsets = borderInsets;
        
        // Push the padding view back from the edges
        paddingConstraintTop_.constant = borderInsets.top;
        paddingConstraintBottom_.constant = -borderInsets.bottom;
        paddingConstraintLeft_.constant = borderInsets.left;
        paddingConstraintRight_.constant = -borderInsets.right;
        
        [self invalidateIntrinsicContentSize];
    }
}

-(void)setPaddingInsets:(UIEdgeInsets)paddingInsets
{
    if (!UIEdgeInsetsEqualToEdgeInsets(_paddingInsets, paddingInsets)) {
        _paddingInsets = paddingInsets;
        [self invalidateIntrinsicContentSize];
    }
}

-(void)setCenter:(CGPoint)center
{
    [super setCenter:center];

    [self.paddingView setCenter:center];
    [self.borderView setCenter:center];
}

-(void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];

    [self.paddingView setHidden:hidden];
    [self.borderView setHidden:hidden];
}



/*
-(void)setText:(NSString *)text
{
    [super setText:text];
    
    NSLog(@"text = %@", text);
    
    [self invalidateIntrinsicContentSize];
}
*/


-(void)setAlpha:(CGFloat)alpha
{
    [super setAlpha:alpha];

    [self.paddingView setAlpha:alpha];
    [self.borderView setAlpha:alpha];
}

-(void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    // Keep preferredMaxLayoutWidth in sync with width
    // See: http://stackoverflow.com/a/17493152/135557
    if (self.preferredMaxLayoutWidth != bounds.size.width) {
        self.preferredMaxLayoutWidth = bounds.size.width;
    }
}

-(void)setPaddingColor:(UIColor *)paddingColor
{
    self.paddingView.backgroundColor = paddingColor;
    _paddingColor = paddingColor;
}

-(void)setBorderColor:(UIColor *)borderColor
{
    self.borderView.backgroundColor = borderColor;
    _borderColor = borderColor;
}

#pragma mark - Layout

- (UIEdgeInsets)alignmentRectInsets
{
    // Override alignmentRectInsets to provide padding between the alignment
    // rect (the box around the text content) and the frame's edges

    // The inset around the label needs to be border width plus padding width
    // (makes room for the padding and border, and the outer edge of this
    // expansion is then used by the constraint system for layout -  it is
    // the act of overriding alignmentRectInsets which moves these boundaries
    // used by the constraint system)
    return (UIEdgeInsets){
        -(self.borderInsets.top + self.paddingInsets.top),
        -(self.borderInsets.left + self.paddingInsets.left),
        -(self.borderInsets.bottom + self.paddingInsets.bottom),
        -(self.borderInsets.right + self.paddingInsets.right)
    };
}

- (void) layoutSubviews {
    [super layoutSubviews];

    void (^constrain)(id __strong *, id, NSLayoutAttribute, CGFloat) = ^(id __strong * p, id view1, NSLayoutAttribute attribute, CGFloat constant){
        *p = [NSLayoutConstraint constraintWithItem:view1
                                          attribute:attribute
                                          relatedBy:NSLayoutRelationEqual
                                             toItem:self
                                          attribute:attribute
                                         multiplier:1.0
                                           constant:constant];
        [self.superview addConstraint:*p];
    };
    
    if (!self.paddingView.superview) {
        [self.superview insertSubview:self.paddingView belowSubview:self];
        constrain(&paddingConstraintTop_, self.paddingView, NSLayoutAttributeTop, self.borderInsets.top);
        constrain(&paddingConstraintBottom_, self.paddingView, NSLayoutAttributeBottom, -self.borderInsets.bottom);
        constrain(&paddingConstraintLeft_, self.paddingView, NSLayoutAttributeLeft, self.borderInsets.left);
        constrain(&paddingConstraintRight_, self.paddingView, NSLayoutAttributeRight, -self.borderInsets.right);
    }
    
    if (!self.borderView.superview) {
        [self.superview insertSubview:self.borderView belowSubview:self.paddingView];
        constrain(&borderConstraintTop_, self.borderView, NSLayoutAttributeTop, 0);
        constrain(&borderConstraintBottom_, self.borderView, NSLayoutAttributeBottom, 0);
        constrain(&borderConstraintLeft_, self.borderView, NSLayoutAttributeLeft, 0);
        constrain(&borderConstraintRight_, self.borderView, NSLayoutAttributeRight, 0);
    }
}

#pragma mark - Touch response

- (BOOL) pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    // Make the border and padding respond to touches too
    return (CGRectContainsPoint(UIEdgeInsetsInsetRect(self.bounds, [self alignmentRectInsets]), point)) ? YES : NO;
}

#pragma mark - Debugging

-(void)debug
{
    // Use for debugging UILabelDynamicHeight - adds random text and uses random border and padding sizes to debug UILabelDynamicHeight
    
    float(^rnd)() = ^(){
        return (float)(rand() % (25 - 1) + 1);
    };
    
    NSString *strToRepeat = @" abc";
    NSString *randStr = [@"" stringByPaddingToLength:rnd() * [strToRepeat length] withString:strToRepeat startingAtIndex:0];
    randStr = [randStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    [UIView animateWithDuration:0.25f
                          delay:0.0f
                        options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         self.font = [UIFont boldSystemFontOfSize:(rand() % (48 - 8) + 8)];
                         [self setText:randStr];
                         
                         self.paddingColor = [UIColor whiteColor];
                         self.borderColor = [UIColor greenColor];
                         self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.2];
                         self.textColor = [UIColor darkGrayColor];
                         
                         self.paddingView.layer.cornerRadius = 3.0f;
                         self.borderView.layer.cornerRadius = 3.0f;
                         
                         //self.layer.borderColor = [UIColor redColor].CGColor;
                         //self.layer.borderWidth = 1.0f;
                         self.layer.cornerRadius = 3.0f;
                         
                         // t l b r
                         [self setPaddingInsets:UIEdgeInsetsMake(rnd(), rnd(), rnd(), rnd())];
                         [self setBorderInsets:UIEdgeInsetsMake(rnd(), rnd(), rnd(), rnd())];
                         NSLog(@"\n{Top, Left, Bottom, Right}\n\tborderInsets:\n\t%@\n\n\tpaddingInsets:\n\t%@",
                               NSStringFromUIEdgeInsets(self.borderInsets),
                               NSStringFromUIEdgeInsets(self.paddingInsets));
                         
                         //Because paddingView and borderView are added to superview, self.superview's
                         //layoutIfNeeded needs to be invoked for paddingView and borderView to animate
                         [self.superview layoutIfNeeded];
                     }
                     completion:^(BOOL finished){
                     }];
}

/*
- (void)drawRect:(CGRect)rect
{       
    [super drawRect:rect];

    float borderSize = 3.0f;

	CGContextRef context = UIGraphicsGetCurrentContext();

    // Bottom border
    CGContextSetFillColorWithColor(context, [UIColor blueColor].CGColor);
    CGContextFillRect(context, CGRectMake(0.0f, self.frame.size.height - borderSize, self.frame.size.width, borderSize));
    
    // Right border
    CGContextSetFillColorWithColor(context, [UIColor blueColor].CGColor);
    CGContextFillRect(context, CGRectMake(0.0f,0.0f, borderSize,self.frame.size.height));
    
    // Left border
    CGContextSetFillColorWithColor(context, [UIColor blueColor].CGColor);
    CGContextFillRect(context, CGRectMake(self.frame.size.width - borderSize,0.0f, borderSize,self.frame.size.height));
}
*/

/*
-(CGSize)intrinsicContentSize
{
    CGSize s = [super intrinsicContentSize];

    return s;
}
*/

@end
