//
//  DetailScrollViewController.h
//  Commons-iOS
//
//  Created by Brion on 1/29/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FileUpload.h"

@class UILabelDynamicHeight;

@protocol DetailScrollViewControllerDelegate <NSObject>
    // Protocol for notifying other view controllers, such as ImageScrollViewController,
    // that the Details view has been scrolled. The ImageScrollViewController uses this
    // so it can adjust the image alpha.
    @property (nonatomic) float detailsScrollNormal;
    @property (weak, nonatomic) UINavigationItem *navigationItem;
    @property (weak, nonatomic) UIView *view;
@end

@interface DetailScrollViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UILabelDynamicHeight *titleTextLabel;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UILabelDynamicHeight *descriptionTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionPlaceholder;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *uploadButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareButton;
@property (weak, nonatomic) IBOutlet UILabel *licenseLabel;
@property (weak, nonatomic) IBOutlet UILabel *licenseNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *ccByImage;
@property (weak, nonatomic) IBOutlet UIImageView *ccSaImage;
@property (weak, nonatomic) IBOutlet UILabel *categoryLabel;
@property (weak, nonatomic) IBOutlet UILabel *categoryListLabel;
@property (weak, nonatomic) IBOutlet UILabel *addCategoryLabel;

@property (weak, nonatomic) IBOutlet UILabelDynamicHeight *categoryDefaultLabel;
@property (weak, nonatomic) IBOutlet UILabelDynamicHeight *licenseDefaultLabel;
@property (weak, nonatomic) IBOutlet UILabelDynamicHeight *deleteButton;

@property (weak, nonatomic) IBOutlet UIView *titleContainer;
@property (weak, nonatomic) IBOutlet UIView *descriptionContainer;
@property (weak, nonatomic) IBOutlet UIView *licenseContainer;
@property (weak, nonatomic) IBOutlet UIView *categoryContainer;
@property (weak, nonatomic) IBOutlet UIView *deleteContainer;

@property (weak, nonatomic) IBOutlet UIView *scrollContainer;

@property (strong, nonatomic) FileUpload *selectedRecord;
@property (strong, nonatomic) NSMutableArray *categoryList;

@property (nonatomic, strong) UIActivityViewController *shareActivityViewController;

@property (strong, nonatomic) id<DetailScrollViewControllerDelegate> delegate;
@property (nonatomic) float detailsScrollNormal;

-(IBAction)deleteButtonPushed:(id)sender;
-(IBAction)shareButtonPushed:(id)sender;
-(void)hideKeyboard;

-(void)scrollByAmount:(float)amount withDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options useXF:(BOOL)useXF then:(void(^)(void))block;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descriptionTextViewHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleTextFieldHeightConstraint;

-(void)ensureScrollingDoesNotExceedThreshold;
-(void)toggle;

@property (nonatomic) BOOL categoriesNeedToBeRefreshed;

@end
