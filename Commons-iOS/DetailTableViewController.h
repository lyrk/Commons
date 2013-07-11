//
//  DetailTableViewController.h
//  Commons-iOS
//
//  Created by Brion on 1/29/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FileUpload.h"

@protocol DetailTableViewControllerDelegate <NSObject>
    // Protocol for notifying other view controllers, such as ImageScrollViewController,
    // that the Details view has been scrolled. The ImageScrollViewController uses this
    // so it can adjust the image alpha.
    @property (nonatomic) float detailsScrollNormal;
    @property (weak, nonatomic) UINavigationItem *navigationItem;
    @property (weak, nonatomic) UIView *view;
    -(void)clearOverlay;
@end

@interface DetailTableViewController : UITableViewController <UITextFieldDelegate, UITextViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionPlaceholder;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *uploadButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareButton;
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

@property (nonatomic, strong) UIActivityViewController *shareActivityViewController;

@property (strong, nonatomic) id<DetailTableViewControllerDelegate> delegate;
@property (nonatomic) float detailsScrollNormal;

-(IBAction)deleteButtonPushed:(id)sender;
-(IBAction)openWikiPageButtonPushed:(id)sender;
-(IBAction)shareButtonPushed:(id)sender;
-(void)hideKeyboard;

-(void)scrollByAmount:(float)amount withDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options useXF:(BOOL)useXF then:(void(^)(void))block;

-(void)ensureScrollingDoesNotExceedThreshold;

@end
