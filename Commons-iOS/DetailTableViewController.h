//
//  DetailTableViewController.h
//  Commons-iOS
//
//  Created by Brion on 1/29/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FileUpload.h"

@interface DetailTableViewController : UITableViewController <UITextFieldDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imagePreview;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionPlaceholder;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *imageSpinner;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *uploadButton;
@property (weak, nonatomic) IBOutlet UILabel *licenseLabel;
@property (weak, nonatomic) IBOutlet UILabel *licenseNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *ccByImage;
@property (weak, nonatomic) IBOutlet UIImageView *ccSaImage;
@property (weak, nonatomic) IBOutlet UITableViewCell *titleCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *descCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *licenseCell;
@property (weak, nonatomic) IBOutlet UILabel *categoryLabel;
@property (weak, nonatomic) IBOutlet UILabel *categoryListLabel;

@property (strong, nonatomic) FileUpload *selectedRecord;
@property (strong, nonatomic) NSMutableArray *categoryList;

- (IBAction)deleteButtonPushed:(id)sender;
- (IBAction)uploadButtonPushed:(id)sender;
- (IBAction)openWikiPageButtonPushed:(id)sender;

@end
