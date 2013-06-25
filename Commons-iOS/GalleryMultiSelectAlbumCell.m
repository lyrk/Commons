//
//  GalleryMultiSelectCell.m
//  Commons-iOS
//
//  Created by Monte Hurd on 6/16/13.

#import "GalleryMultiSelectAlbumCell.h"

@implementation GalleryMultiSelectAlbumCell

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        self.backgroundView.backgroundColor = [UIColor whiteColor];
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
        self.selectedBackgroundView.backgroundColor = [UIColor blueColor];
    }
    return self;
}

@end
