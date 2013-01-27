//
//  TableViewController.h
//  Commons-iOS
//
//  Created by Brion on 1/25/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface TableViewController : UITableViewController <UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *uploadButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *choosePhotoButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *takePhotoButton;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

- (IBAction)uploadButtonPushed:(id)sender;
- (IBAction)takePhotoButtonPushed:(id)sender;
- (IBAction)choosePhotoButtonPushed:(id)sender;

@end
