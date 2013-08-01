//
//  ImageResizer.h
//  Commons-iOS
//
//  Created by Monte Hurd on 8/1/13.

#import <Foundation/Foundation.h>

@interface ImageResizer : NSObject

@property (nonatomic, retain) NSString *imagePath;
@property (nonatomic, retain) NSString *thumbImagePath;
@property (nonatomic) CGSize desiredSize;

// Create desiredSize version of image at imagePath saving the new image to thumbImagePath
// (only creates the new image if it doesn't already exist)
-(void)createThumbImage;

@end
