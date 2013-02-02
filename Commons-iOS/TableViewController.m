//
//  TableViewController.m
//  Commons-iOS
//
//  Created by Brion on 1/25/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "TableViewController.h"
#import "CommonsApp.h"
#import "FileUploadCell.h"
#import "DetailTableViewController.h"

@interface TableViewController ()

@end

@implementation TableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        // Camera is available
    } else {
        // Clicking 'take photo' in simulator *will* crash, so disable the button.
        self.takePhotoButton.enabled = NO;
    }

    CommonsApp *app = [CommonsApp singleton];
    self.fetchedResultsController = [app fetchUploadRecords];
    self.fetchedResultsController.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"DetailSegue"]) {
        FileUpload *record = (FileUpload *)[self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForSelectedRow]];
        DetailTableViewController *view = [segue destinationViewController];
        view.selectedRecord = record;
    }
}

- (void)viewDidUnload {
    [self setSettingsButton:nil];
    [self setUploadButton:nil];
    [self setTakePhotoButton:nil];
    [self setChoosePhotoButton:nil];
    [self setTakePhotoButton:nil];
    [self setTableView:nil];
    [self setFetchedResultsController:nil];
    self.popover = nil;
    [self setRefreshButton:nil];
    [super viewDidUnload];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (self.fetchedResultsController != nil) {
        NSLog(@"rows: %d objects", self.fetchedResultsController.fetchedObjects.count);
        return self.fetchedResultsController.fetchedObjects.count;
    } else {
        return 0;
    }
}

- (void)configureCell:(FileUploadCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    CommonsApp *app = CommonsApp.singleton;
    FileUpload *record = (FileUpload *)[self.fetchedResultsController objectAtIndexPath:indexPath];

    cell.titleLabel.text = record.title;
    if (record.thumbnailFile) {
        cell.image.image = [app loadThumbnail: record.thumbnailFile];
    } else {
        cell.image.image = nil;
    }
    if (record.complete.boolValue) {
        // Old upload, already complete.
        // We have the title; fetch thumbnails and such on demand.
        cell.sizeLabel.text = [app prettyDate:record.created];
        cell.progressBar.hidden = YES;
    } else {
        // Queued upload, not yet complete.
        // We have local data & progress info.
        cell.sizeLabel.text = record.prettySize;
        cell.progressBar.hidden = NO;
        cell.progressBar.progress = record.progress.floatValue;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"protoCell";
    FileUploadCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    /*
    CommonsApp *app = CommonsApp.singleton;
    FileUpload *record = (FileUpload *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    app.selectedRecord = record;
    */
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
    [CommonsApp.singleton prepareImage:info onCompletion:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
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
                    [app beginUpload:record completion:^() {
                        NSLog(@"completed an upload, going on to next");
                        run();
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
    [CommonsApp.singleton refreshHistory];
}

- (void)cancelButtonPushed:(id)sender {

    CommonsApp *app = [CommonsApp singleton];
    [app cancelCurrentUpload];

    self.navigationItem.rightBarButtonItem = [self uploadBarButtonItem];
}

#pragma mark - NSFetchedResultsController Delegate Methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;

    switch (type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeUpdate:
            [self configureCell:(FileUploadCell *) [tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;

        case NSFetchedResultsChangeMove:
            [tableView                   deleteRowsAtIndexPaths:[NSArray
                    arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView                      insertRowsAtIndexPaths:[NSArray
                    arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
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
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

#pragma mark - Popover Controller Delegate Methods

/**
 * Release memory after popover controller is dismissed.
 */
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
}


@end
