//
//  GalleryMultiSelectGroupAssetsVC.h
//  Commons-iOS
//
//  Created by Monte Hurd on 6/16/13.

#import <UIKit/UIKit.h>

@interface GalleryMultiSelectCollectionVC : UICollectionViewController <UICollectionViewDataSource, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

// GalleryMultiSelectCollectionVC allows more than one photo to be selected, but presently it is being used as a
// drop-on replacement for the built-in image picker. Presently when a single image is selected from an album the
// method below is invoked immediately.
@property(copy) void(^didFinishPickingMediaWithInfo)(NSDictionary *info);

@end
