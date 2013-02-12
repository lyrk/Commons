//
//  MyUploadsViewController.m
//  Commons-iOS
//
//  Created by Brion on 2/5/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "MyUploadsViewController.h"
#import "CommonsApp.h"
#import "ImageListCell.h"
#import "DetailTableViewController.h"
#import "MWI18N/MWI18N.h"

@interface MyUploadsViewController ()

@end

@implementation MyUploadsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Set up refresh
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshButtonPushed:)
             forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.refreshControl];

    // l10n
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:[MWMessage forKey:@"contribs-refresh"].text];
    self.navigationItem.title = [MWMessage forKey:@"contribs-title"].text;
    self.settingsButton.title = [MWMessage forKey:@"contribs-settings-button"].text;
    self.uploadButton.title = [MWMessage forKey:@"contribs-upload-button"].text;
    self.choosePhotoButton.title = [MWMessage forKey:@"contribs-photo-library-button"].text;
    
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        // Camera is available
    } else {
        // Clicking 'take photo' in simulator *will* crash, so disable the button.
        self.takePhotoButton.enabled = NO;
    }
    
    CommonsApp *app = [CommonsApp singleton];
    self.fetchedResultsController = [app fetchUploadRecords];
    self.fetchedResultsController.delegate = self;
    
    if (app.username == nil || [app.username isEqualToString:@""]) {
        [self performSegueWithIdentifier:@"SettingsSegue" sender:self];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setSettingsButton:nil];
    [self setUploadButton:nil];
    [self setChoosePhotoButton:nil];
    [self setTakePhotoButton:nil];
    [self setRefreshButton:nil];

    [self setFetchedResultsController:nil];
    self.popover = nil;
    self.selectedRecord = nil;

    [super viewDidUnload];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"DetailSegue"]) {
        DetailTableViewController *view = [segue destinationViewController];
        view.selectedRecord = self.selectedRecord;
    }
}

#pragma mark - Image Picker Controller Delegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    /*
     
     Photo:
     {
     DPIHeight: 72,
     DPIWidth 72,
     Orientation: 6,
     "{Exif}": {...},
     "{TIFF}": {...},
     UIImagePickerControllerMediaType: "public.image",
     UIImagePickerControllerOriginalImage: <UIImage>
     }
     
     Gallery:
     {
     UIImagePickerControllerMediaType = "public.image";
     UIImagePickerControllerOriginalImage = "<UIImage: 0x1cd44980>";
     UIImagePickerControllerReferenceURL = "assets-library://asset/asset.JPG?id=E248436B-4DB7-4583-BB6C-6073C332B9A6&ext=JPG";
     }
     */
    NSLog(@"picked: %@", info);
    [CommonsApp.singleton prepareImage:info];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    self.uploadButton.enabled = YES;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSLog(@"canceled");
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Interface Items

- (UIBarButtonItem *)uploadBarButtonItem {
    
    UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithTitle:@"Upload"
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(uploadButtonPushed:)];
    return btn;
}

- (UIBarButtonItem *)cancelBarButtonItem {
    
    UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(cancelButtonPushed:)];
    return btn;
}

#pragma mark - Interface Actions

- (IBAction)uploadButtonPushed:(id)sender {
    
    CommonsApp *app = [CommonsApp singleton];
    
    // Only allow uploads if user is logged in
    if (![app.username isEqualToString:@""] && ![app.password isEqualToString:@""]) {
        // User is logged in
        
        if ([self.fetchedResultsController.fetchedObjects count] > 0) {
            
            self.navigationItem.rightBarButtonItem = [self cancelBarButtonItem];
            
            NSLog(@"Upload ye files!");
            
            __block void (^run)() = ^() {
                FileUpload *record = [app firstUploadRecord];
                if (record != nil) {
                    MWPromise *upload = [app beginUpload:record];
                    [upload done:^(id arg) {
                        NSLog(@"completed an upload, going on to next");
                        run();
                    }];
                    [upload fail:^(NSError *error) {
                        
                         NSLog(@"Upload failed: %@", [error localizedDescription]);
                        
                         self.navigationItem.rightBarButtonItem = [self uploadBarButtonItem];
                        
                         UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[MWMessage forKey:@"error-upload-failed"].text
                                                                             message:[error localizedDescription]
                                                                            delegate:nil
                                                                   cancelButtonTitle:[MWMessage forKey:@"error-dismiss"].text
                                                                   otherButtonTitles:nil];
                         [alertView show];
                        
                         run = nil;
                    }];
                } else {
                    NSLog(@"no more uploads");
                    self.navigationItem.rightBarButtonItem = [self uploadBarButtonItem];
                    run = nil;
                }
            };
            run();
        }
    }
    else {
        // User is not logged in
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[MWMessage forKey:@"error-nologin-title"].text
                                                            message:[MWMessage forKey:@"error-nologin-text"].text
                                                           delegate:nil
                                                  cancelButtonTitle:[MWMessage forKey:@"error-dismiss"].text
                                                  otherButtonTitles:nil];
        [alertView show];
        
        NSLog(@"Can't upload because user is not logged in.");
    }
}

- (IBAction)takePhotoButtonPushed:(id)sender {
    NSLog(@"Take photo");
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

/**
 * Show the image picker.
 * On iPad, show a popover.
 * @param sender
 */
- (IBAction)choosePhotoButtonPushed:(id)sender
{
    NSLog(@"Open gallery");
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (!self.popover) { // prevent crash when choose photo is tapped twice in succession
            self.popover = [[UIPopoverController alloc] initWithContentViewController:picker];
            self.popover.delegate = self;
            [self.popover presentPopoverFromBarButtonItem:self.choosePhotoButton
                                 permittedArrowDirections:UIPopoverArrowDirectionAny
                                                 animated:YES];
        }
    } else {
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (IBAction)refreshButtonPushed:(id)sender {
    MWPromise *refresh = [CommonsApp.singleton refreshHistory];
    [refresh done:^(id arg) {
        [self.refreshControl endRefreshing];
    }];
}

- (void)cancelButtonPushed:(id)sender {
    
    CommonsApp *app = [CommonsApp singleton];
    [app cancelCurrentUpload];
    
    self.navigationItem.rightBarButtonItem = [self uploadBarButtonItem];
}

#pragma mark - NSFetchedResultsController Delegate Methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    /*[self.tableView beginUpdates];*/
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.collectionView insertItemsAtIndexPaths:@[newIndexPath]];
            {
                FileUpload *record = (FileUpload *)anObject;
                if (!record.complete.boolValue) {
                    // This will go crazy if we import multiple items at once :)
                    self.selectedRecord = record;
                    [self performSegueWithIdentifier:@"DetailSegue" sender:self];
                }
            }
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:(ImageListCell *)[self.collectionView cellForItemAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.collectionView moveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
            [self configureCell:(ImageListCell *)[self.collectionView cellForItemAtIndexPath:newIndexPath] atIndexPath:newIndexPath];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    /*[self.tableView endUpdates];*/
}

#pragma mark - Popover Controller Delegate Methods

/**
 * Release memory after popover controller is dismissed.
 * @param popover controller
 */
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
}


#pragma mark - UICollectionViewDelegate methods

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FileUpload *record = (FileUpload *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    self.selectedRecord = record;
    return indexPath;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedRecord = nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout  *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // iPad: fit 3 across in portrait or 4 across landscape
        return CGSizeMake(240.0f, 200.0f);
    } else {
        // iPhone/iPod: fit 1 across in portrait
        return CGSizeMake(300.0f, 200.0f);
    }
}

#pragma mark - UICollectionViewDataSource methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.fetchedResultsController != nil) {
        NSLog(@"rows: %d objects", self.fetchedResultsController.fetchedObjects.count);
        return self.fetchedResultsController.fetchedObjects.count;
    } else {
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ImageListCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"imageListCell"
                                                                    forIndexPath:indexPath];
    
    // Configure the cell...
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

/**
 * Configure the attributes of a table cell.
 * @param cell
 * @param index path
 */
- (void)configureCell:(ImageListCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    CommonsApp *app = CommonsApp.singleton;
    FileUpload *record = (FileUpload *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSString *title = record.title;
    cell.title = title;
    cell.titleLabel.text = title;
    /*
    if (record.thumbnailFile) {
        cell.image.image = [app loadThumbnail: record.thumbnailFile];
    } else {
        cell.image.image = nil;
    }
    */

    NSURL *thumbURL;
    if (record.complete.boolValue) {
        thumbURL = [NSURL URLWithString:record.thumbnailURL];
    } else {
        thumbURL = [NSURL fileURLWithPath:record.localFile];
    }
    if (cell.thumbnailURL && [cell.thumbnailURL isEqual:thumbURL]) {
        // Nothing to do!
    } else {
        cell.thumbnailURL = thumbURL;
        cell.image.image = nil;
        MWPromise *fetch = [record fetchThumbnail];
        [fetch done:^(UIImage *image) {
            if ([cell.title isEqualToString:title]) {
                cell.image.image = image;
            }
        }];
        [fetch fail:^(NSError *error) {
            NSLog(@"failed to load thumbnail");
        }];
    }
    if (record.complete.boolValue) {
        // Old upload, already complete.
        cell.statusLabel.text = [app prettyDate:record.created];
        cell.progressBar.hidden = YES;
    } else {
        // Queued upload, not yet complete.
        // We have local data & progress info.
        if (record.progress.floatValue == 0.0f) {
            cell.progressBar.hidden = YES;
            cell.statusLabel.text = [MWMessage forKey:@"contribs-state-queued"].text;
        } else {
            cell.progressBar.hidden = NO;
            cell.statusLabel.text = [MWMessage forKey:@"contribs-state-uploading"].text;
            cell.progressBar.progress = record.progress.floatValue;
        }
    }
}


@end
