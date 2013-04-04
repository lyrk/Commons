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

@interface MyUploadsViewController : UIViewController <UINavigationControllerDelegate,
UIImagePickerControllerDelegate, NSFetchedResultsControllerDelegate, UIPopoverControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource,UIScrollViewDelegate, UIGestureRecognizerDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *uploadButton;
@property (weak, nonatomic) IBOutlet UIButton *addMediaButton;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *choosePhotoButton;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) UIRefreshControl *refreshControl;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) UIPopoverController *popover;
@property (strong, nonatomic) FileUpload *selectedRecord;

- (IBAction)uploadButtonPushed:(id)sender;
- (IBAction)takePhotoButtonPushed:(id)sender;
- (IBAction)choosePhotoButtonPushed:(id)sender;
- (IBAction)refreshButtonPushed:(id)sender;
- (IBAction)addMediaButtonPushed:(id)sender;

@end
