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
#import "mwapi/MWApi.h"

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
        // FIXME this doesn't take effect for some reason!
        self.takePhotoButton.enabled = NO;
    }

    CommonsApp *app = [CommonsApp singleton];
    self.fetchedResultsController = [app fetchUploadRecords];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CommonsApp *app = CommonsApp.singleton;

    static NSString *CellIdentifier = @"protoCell";
    FileUploadCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    FileUpload *record = (FileUpload *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.titleLabel.text = record.title;
    cell.sizeLabel.text = [app prettySize:record.fileSize.integerValue];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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
}

- (void)viewDidUnload {
    [self setSettingsButton:nil];
    [self setUploadButton:nil];
    [self setTakePhotoButton:nil];
    [self setChoosePhotoButton:nil];
    [self setTakePhotoButton:nil];
    [self setTableView:nil];
    [self setFetchedResultsController:nil];
    [super viewDidUnload];
}

- (IBAction)uploadButtonPushed:(id)sender {
    NSLog(@"Upload ye files!");
    
    CommonsApp *app = CommonsApp.singleton;
    NSString *username = app.username;
    NSString *password = app.password;
    NSString *desc = @"temporary description text";
    NSString *filename = [NSString stringWithFormat:@"Testfile %li.jpg", (long)[[NSDate date] timeIntervalSince1970]];
    
    // @FIXMEEEE
    UIImage *image = app.image;
    NSData *jpeg = UIImageJPEGRepresentation(image, 0.9);
    
    NSLog(@"username: %@, desc: %@, jpeg: %i bytes", username, desc, (int)(jpeg.length));
    
    // hack hack hack
    // Upload the file
    NSURL *url = [NSURL URLWithString:@"https://test2.wikipedia.org/w/api.php"];
    MWApi *mwapi = [[MWApi alloc] initWithApiUrl:url];
    
    // Run an indeterminate activity indicator during login validation...
    //[self.activityIndicator startAnimating];
    [mwapi loginWithUsername:username andPassword:password withCookiePersistence:YES onCompletion:^(MWApiResult *loginResult) {
        NSLog(@"login: %@", loginResult.data[@"login"][@"result"]);
        //[self.activityIndicator stopAnimating];
        if (mwapi.isLoggedIn) {
            //[self.progressBar setProgress:0.0f];
            //self.progressBar.hidden = NO;
            void (^progress)(NSInteger, NSInteger) = ^(NSInteger bytesSent, NSInteger bytesTotal) {
                //self.progressBar.progress = (float)bytesSent / (float)bytesTotal;
            };
            void (^complete)(MWApiResult *) = ^(MWApiResult *uploadResult) {
                NSLog(@"upload: %@", uploadResult.data);
                
                NSLog(@"done uploading...");
                //self.progressBar.hidden = YES;
            };
            [mwapi uploadFile:filename
                 withFileData:jpeg
                         text:desc
                      comment:@"Uploaded with Commons for iOS"
                 onCompletion:complete
                   onProgress:progress];
        } else {
            NSLog(@"not logged in");
        }
    }];
}

- (IBAction)takePhotoButtonPushed:(id)sender {
    NSLog(@"Take photo");
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)choosePhotoButtonPushed:(id)sender {
    NSLog(@"Open gallery");
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

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
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSLog(@"canceled");
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
