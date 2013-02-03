//
//  TableViewController.h
//  Commons-iOS
//
//  Created by Brion on 1/25/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "FileUpload.h"

@interface TableViewController : UITableViewController <UINavigationControllerDelegate,
        UIImagePickerControllerDelegate, NSFetchedResultsControllerDelegate, UIPopoverControllerDelegate, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *uploadButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *choosePhotoButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *takePhotoButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) UIPopoverController *popover;
@property (strong, nonatomic) FileUpload *selectedRecord;

- (IBAction)uploadButtonPushed:(id)sender;
- (IBAction)takePhotoButtonPushed:(id)sender;
- (IBAction)choosePhotoButtonPushed:(id)sender;
- (IBAction)refreshButtonPushed:(id)sender;

@end
