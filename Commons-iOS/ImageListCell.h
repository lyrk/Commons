//
//  ImageListCell.h
//  Commons-iOS
//
//  Created by Brion on 2/5/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ProgressView;

@interface ImageListCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet ProgressView *infoBox;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *indexLabel;

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSURL *thumbnailURL;

-(void)resizeTitleLabelWithTitle:(NSString *)title fileName:(NSString *)fileName;
//-(void)showPlaceHolderImage;

@end
