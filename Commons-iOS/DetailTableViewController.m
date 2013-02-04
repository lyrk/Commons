//
//  DetailTableViewController.m
//  Commons-iOS
//
//  Created by Brion on 1/29/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "DetailTableViewController.h"
#import "CommonsApp.h"
#import "WebViewController.h"
#import "ImageScrollViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface DetailTableViewController ()

@end

@implementation DetailTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

/**
 * View has loaded.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Load up the selected record
    CommonsApp *app = CommonsApp.singleton;
    FileUpload *record = self.selectedRecord;

    if (record != nil) {
        self.titleTextField.text = record.title;
        self.descriptionTextView.text = record.desc;
        if (record.complete.boolValue) {
            // Completed upload...
            self.titleTextField.enabled = NO;
            self.descriptionTextView.editable = NO;
            self.deleteButton.enabled = NO; // fixme in future, support deleting uploaded items
            self.actionButton.enabled = YES; // open link or share on the web

            // Fetch medium thumbnail from the interwebs
            CGFloat density = [UIScreen mainScreen].scale;
            CGSize size = CGSizeMake(284.0f * density, 212.0f * density);

            // Start by showing the locally stored thumbnail
            if (record.thumbnailFile != nil) {
                self.imagePreview.image = [app loadThumbnail:record.thumbnailFile];
            }

            self.imageSpinner.hidden = NO;
            [app fetchWikiImage:record.title
                           size:size
                   onCompletion:^(UIImage *image) {
                       self.imageSpinner.hidden = YES;

                       // provide a smooth image transition between thumbnail and wiki image
                       CATransition *transition = [CATransition animation];
                       transition.duration = 0.5f;
                       transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                       transition.type = kCATransitionFade;
                       [self.imagePreview.layer addAnimation:transition forKey:nil];
                       self.imagePreview.image = image;

                   }
                      onFailure:^(NSError *error) {
                          NSLog(@"Failed to fetch wiki image: %@", [error localizedDescription]);
                          self.imageSpinner.hidden = YES;
                      }
             ];

        } else {
            // Locally queued file...
            self.titleTextField.enabled = YES;
            self.descriptionTextView.editable = YES;
            self.deleteButton.enabled = YES;
            self.actionButton.enabled = NO;

            // Use the pre-uploaded file as the medium thumbnail
            self.imagePreview.image = [app loadImage:record.localFile];
            if (self.imagePreview.image == nil) {
                // Can't read that file format natively; use our thumbnail icon
                self.imagePreview.image = [app loadThumbnail:record.thumbnailFile];
            }
            self.imageSpinner.hidden = YES;
        }
    } else {
        NSLog(@"This isn't right, have no selected record in detail view");
    }

    // Set delegates so we know when fields change...
    self.titleTextField.delegate = self;
    self.descriptionTextView.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

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


#pragma mark -

- (void)popViewControllerAnimated {
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"OpenPageSegue"]) {
        if (self.selectedRecord) {
            WebViewController *view = [segue destinationViewController];
            NSString *pageTitle = [@"File:" stringByAppendingString:self.selectedRecord.title];
            view.targetURL = [CommonsApp.singleton URLForWikiPage:pageTitle];
        }
    }
    else if ([segue.identifier isEqualToString:@"OpenImageSegue"]) {
        
        if (self.selectedRecord) {
            
            ImageScrollViewController *view = [segue destinationViewController];
            
            CGFloat density = [UIScreen mainScreen].scale;
            CGSize size = CGSizeMake(1024.0f * density, 1024.0f * density);
            
            FileUpload *record = self.selectedRecord;
            if (record != nil) {
                
                view.title = record.title;
                
                if (record.complete.boolValue) {
                    // Internet
                    
                    [[CommonsApp singleton] fetchWikiImage:record.title
                                                      size:size
                                              onCompletion:^(UIImage *image) {
                                                  
                                                  [view setImage:image];
                                              }
                                                 onFailure:^(NSError *error) {
                                                     
                                                     NSLog(@"Failed to download image: %@", [error localizedDescription]);
                                                     
                                                     // Pop back after a second if image failed to download
                                                     [self performSelector:@selector(popViewControllerAnimated) withObject:nil afterDelay:1];
                                                 }];
                }
                else {
                    // Local
                    
                    view.image = self.imagePreview.image;
                }
                
            }
            
        }
        
    }
    
}

- (void)viewDidUnload {
    [self setImagePreview:nil];
    [self setTitleTextField:nil];
    [self setDescriptionTextView:nil];
    [self setSelectedRecord:nil];
    [self setImageSpinner:nil];
    [self setDeleteButton:nil];
    [self setActionButton:nil];
    [super viewDidUnload];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    CommonsApp *app = CommonsApp.singleton;
    FileUpload *record = self.selectedRecord;
    NSLog(@"setting title: %@", self.titleTextField.text);
    record.title = self.titleTextField.text;
    [app saveData];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    CommonsApp *app = CommonsApp.singleton;
    FileUpload *record = self.selectedRecord;
    NSLog(@"setting desc: %@", self.descriptionTextView.text);
    record.desc = self.descriptionTextView.text;
    [app saveData];
}

- (IBAction)deleteButtonPushed:(id)sender {
    CommonsApp *app = CommonsApp.singleton;
    [app deleteUploadRecord:self.selectedRecord];
    self.selectedRecord = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

@end
