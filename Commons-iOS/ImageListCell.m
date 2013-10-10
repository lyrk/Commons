//
//  ImageListCell.m
//  Commons-iOS
//
//  Created by Brion on 2/5/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "ImageListCell.h"
#import "ProgressView.h"
//#import "UIView+Debugging.h"

#define PLACEHOLDER_IMAGE_NAME @"commons-logo.png"

@interface ImageListCell()

@property (nonatomic) BOOL subviewsConstrained;

@end

@implementation ImageListCell{
    UIView *titleBackground_;
    UIImage *placeHolderImage_;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        titleBackground_ = [[UIView alloc] init];
        placeHolderImage_ = nil;
        //placeHolderImage_ = [self tintImage:[UIImage imageNamed:PLACEHOLDER_IMAGE_NAME]
        //                          withColor:[UIColor colorWithWhite:1.0f alpha:0.05f]
        //                       blendingMode:kCGBlendModeDestinationIn];
        titleBackground_.backgroundColor = [UIColor clearColor];
        self.titleLabelMargin = @0.0f;
        self.subviewsConstrained = NO;
        //[self randomlyColorSubviews];
    }
    return self;
}

- (UIImage *)tintImage:(UIImage *)image withColor:(UIColor *)tintColor blendingMode:(CGBlendMode)blendMode
{
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0f);
    [tintColor setFill];
    CGRect bounds = CGRectMake(0, 0, image.size.width, image.size.height);
    UIRectFill(bounds);
    [image drawInRect:bounds blendMode:blendMode alpha:1.0f];
    
    if (blendMode != kCGBlendModeDestinationIn)
        [image drawInRect:bounds blendMode:kCGBlendModeDestinationIn alpha:1.0];
    
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return tintedImage;
}

-(void)resizeTitleLabelWithTitle:(NSString *)title fileName:(NSString *)fileName
{
    float margin = [self.titleLabelMargin floatValue];
    self.titleLabel.preferredMaxLayoutWidth = self.infoBox.frame.size.width - margin;

    // Convert the label's text to attributed text and apply styling attributes and size label to fit the
    // newly styled text
    self.titleLabel.numberOfLines = 0; // zero means use as many lines as needed
    self.titleLabel.attributedText = [self attributedStringVersionOfCellTitle:title forFileName:fileName];
}

//-(void)showPlaceHolderImage
//{
//    self.image.image = placeHolderImage_;
//}

-(void)constrainSubviews
{
    if (self.subviewsConstrained) return;
    self.subviewsConstrained = YES;

    // Constrain infoBox height to titleLabel's height plus margin
    // (titleLabel height is variable)
    float margin = [self.titleLabelMargin floatValue] / 2.0f;
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.infoBox
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.titleLabel
                                                     attribute:NSLayoutAttributeHeight
                                                    multiplier:1.0
                                                      constant:margin]];

    // Constrain the titleLabel horizontally with margin
    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat: @"H:|-margin-[titleLabel]-margin-|"
                          options:  0
                          metrics:  @{@"margin" : @(margin)}
                          views:    @{@"titleLabel" : self.titleLabel}
                          ]];
}

-(NSAttributedString *)attributedStringVersionOfCellTitle:(NSString *)title forFileName:(NSString *) fileName
{
    // Creates attributed string version of title parameter
    // Changes color of filename if found in the string
    
    if (!title) title = @"";
    if (!fileName) fileName = @"";
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    paragraphStyle.lineSpacing = 2.0f;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:title attributes:nil];
    NSRange fileNameRange = [title rangeOfString:fileName];
    NSRange wholeRange = NSMakeRange(0, title.length);
    
    /*
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor: [UIColor colorWithWhite:0.0f alpha:1.0f]];
    [shadow setShadowOffset:CGSizeMake (1.0, 1.0)];
    [shadow setShadowBlurRadius:0];
    */
    
    [attStr beginEditing];
    [attStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:wholeRange];
    [attStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:1.0f alpha:0.5f] range:wholeRange];
    [attStr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:fileNameRange];
    [attStr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:12.0f] range:wholeRange];
    [attStr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:14.0f] range:fileNameRange];
    [attStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:wholeRange];
    //[attStr addAttribute:NSShadowAttributeName value:shadow range:wholeRange];
    [attStr endEditing];
    
    return attStr;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
