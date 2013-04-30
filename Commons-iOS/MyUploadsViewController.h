//
//  MyUploadsViewController.h
//  Commons-iOS
//
//  Created by Brion on 2/5/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "FileUpload.h"

@interface MyUploadsViewController : UIViewController <UINavigationControllerDelegate,UIImagePickerControllerDelegate, NSFetchedResultsControllerDelegate, UIPopoverControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource,UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *uploadButton;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) UIPopoverController *popover;
@property (strong, nonatomic) FileUpload *selectedRecord;

@property (weak, nonatomic) IBOutlet UIButton *aboutButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UIButton *addMediaButton;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *choosePhotoButton;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

- (IBAction)choosePhotoButtonPushed:(id)sender;
- (IBAction)takePhotoButtonPushed:(id)sender;
- (IBAction)addMediaButtonPushed:(id)sender;
- (IBAction)settingsButtonPushed:(id)sender;
- (IBAction)refreshButtonPushed:(id)sender;
- (IBAction)uploadButtonPushed:(id)sender;

@end
