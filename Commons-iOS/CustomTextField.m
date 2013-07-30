
#import "CustomTextField.h"

@implementation CustomTextField{
}


- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        // Add a little padding to the left of any text entered
        UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 28, 20)];
        paddingView.backgroundColor = [UIColor clearColor];
        self.leftView = paddingView;
        self.leftViewMode = UITextFieldViewModeAlways;
        
        // Add padding to the right too, but only when the clear icon is not visible
        paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 28, 20)];
        paddingView.backgroundColor = [UIColor clearColor];
        self.rightView = paddingView;
        self.rightViewMode = UITextFieldViewModeUnlessEditing;
    }
    return self;
}

/*
- (CGRect)textRectForBounds:(CGRect)bounds
{
	return CGRectInset(bounds, 15, 15);
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
	return CGRectInset(bounds, 15, 15);
}

- (void)drawRect:(CGRect)rect
{

}
*/
@end
