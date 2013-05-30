//
//  ImageListCell.m
//  Commons-iOS
//
//  Created by Brion on 2/5/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "ImageListCell.h"
#import "ProgressView.h"

#define PLACEHOLDER_IMAGE_NAME @"commons-logo.png"

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
    float margin = 15.0f;
    float minHeight = 20.0f;
    
    // Resets label frame width, must happen before the attributed string is sized
    self.titleLabel.frame = CGRectInset(self.infoBox.frame, margin, 0.0f);
    
    // Convert the label's text to attributed text and apply styling attributes and size label to fit the
    // newly styled text
    self.titleLabel.numberOfLines = 0; // zero means use as many as needed
    
    // Get pretty version of
    self.titleLabel.attributedText = [self attributedStringVersionOfCellTitle:title forFileName:fileName];
    
    // Resize the label to fit its newly styled text
    [self.titleLabel sizeToFit];
    
    // If label height less than minHeight, increase the margin accordingly
    if (self.titleLabel.frame.size.height < minHeight) {
        margin += ((minHeight - self.titleLabel.frame.size.height) / 2.0f);
    }
    
    // Increase the size of the progressView by size of newly resized label plus margin
    self.infoBox.frame = CGRectMake(self.infoBox.frame.origin.x, self.frame.size.height - self.titleLabel.frame.size.height - (margin * 2.0f), self.infoBox.frame.size.width, self.titleLabel.frame.size.height +  (margin * 2.0f));
    
    // Ensure label is still centered in resized progressView
    self.titleLabel.center = CGPointMake(self.infoBox.center.x, self.infoBox.frame.size.height / 2.0f);

    // Left align
    self.titleLabel.frame = CGRectMake(self.infoBox.frame.origin.x + margin, self.titleLabel.frame.origin.y, self.titleLabel.frame.size.width, self.titleLabel.frame.size.height);
    
    // Use titleBackground as a styled background for the label - easy way to add surrounding
    // visual without actually resizing the label (which would cause the text to be redrawn
    // which would mess with the margins)
    return;

    UIColor *c1 = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.15f];
    UIColor *c2 = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.20f];
    
    titleBackground_.frame = CGRectInset(self.titleLabel.frame, -12.0f, -8.0f);
    titleBackground_.backgroundColor = c1;
    
    titleBackground_.layer.cornerRadius = 10.0f;
    titleBackground_.layer.masksToBounds = YES;
    
    titleBackground_.layer.borderColor = c2.CGColor;
    titleBackground_.layer.borderWidth = 2.0;

    if(![self.infoBox.subviews containsObject:titleBackground_])
    {
        [self.infoBox insertSubview:titleBackground_ belowSubview:self.titleLabel];
    }
}

//-(void)showPlaceHolderImage
//{
//    self.image.image = placeHolderImage_;
//}

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
    
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor: [UIColor colorWithWhite:0.0f alpha:1.0f]];
    [shadow setShadowOffset:CGSizeMake (1.0, 1.0)];
    [shadow setShadowBlurRadius:0];
    
    [attStr beginEditing];
    [attStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:wholeRange];
    [attStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:1.0f alpha:0.5f] range:wholeRange];
    [attStr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:fileNameRange];
    [attStr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:12.0f] range:wholeRange];
    [attStr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:14.0f] range:fileNameRange];
    [attStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:wholeRange];
    [attStr addAttribute:NSShadowAttributeName value:shadow range:wholeRange];
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
