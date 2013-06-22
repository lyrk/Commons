//
//  GalleryMultiSelectAssetCell.m
//  Commons-iOS
//
//  Created by Monte Hurd on 6/21/13.

#import "GalleryMultiSelectAssetCell.h"

@implementation GalleryMultiSelectAssetCell

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        self.backgroundView.backgroundColor = [UIColor whiteColor];
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
        self.selectedBackgroundView.backgroundColor = [UIColor blueColor];        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self addSubview:self.imageView];
    }
    return self;
}
@end
