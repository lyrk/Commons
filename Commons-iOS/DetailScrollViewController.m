//
//  DetailScrollViewController.m
//  Commons-iOS
//
//  Created by Brion on 1/29/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "DetailScrollViewController.h"
#import "CommonsApp.h"
#import <QuartzCore/QuartzCore.h>
#import "MWI18N/MWMessage.h"
#import "MyUploadsViewController.h"
#import "CategorySearchTableViewController.h"
#import "CategoryDetailTableViewController.h"
#import "AppDelegate.h"
#import "LoadingIndicator.h"
#import "DescriptionParser.h"
#import "MWI18N.h"
#import "AspectFillThumbFetcher.h"
#import "OpenInBrowserActivity.h"
#import "UIView+Debugging.h"
#import "UILabelDynamicHeight.h"

#define URL_IMAGE_LICENSE @"https://creativecommons.org/licenses/by-sa/3.0/"

#define DETAIL_LABEL_COLOR [UIColor whiteColor]
#define DETAIL_VIEW_COLOR [UIColor blackColor]

#define DETAIL_BORDER_COLOR [UIColor colorWithWhite:1.0f alpha:0.75f]
#define DETAIL_BORDER_WIDTH 0.0f
#define DETAIL_BORDER_RADIUS 0.0f

#define DETAIL_TABLE_CATEGORIES_BACKGROUND_COLOR [UIColor colorWithWhite:1.0f alpha:0.1f]

#define DETAIL_EDITABLE_TEXTBOX_BACKGROUND_COLOR [UIColor colorWithWhite:1.0f alpha:0.5f]
#define DETAIL_EDITABLE_TEXTBOX_TEXT_COLOR [UIColor whiteColor]
#define DETAIL_NON_EDITABLE_TEXTBOX_BACKGROUND_COLOR [UIColor colorWithWhite:1.0f alpha:0.1f]

#define DETAIL_DOCK_DISTANCE_FROM_BOTTOM ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 146.0f : 126.0f)

#define DETAIL_TABLE_MAX_OVERLAY_ALPHA 0.85f

#define DETAIL_TITLE_PADDING_INSET UIEdgeInsetsMake(17.0f, 11.0f, 17.0f, 11.0f)
#define DETAIL_DESCRIPTION_PADDING_INSET UIEdgeInsetsMake(17.0f, 11.0f, 17.0f, 11.0f)
#define DETAIL_CATEGORY_PADDING_INSET UIEdgeInsetsMake(17.0f, 11.0f, 17.0f, 11.0f)


@interface DetailScrollViewController ()

@property (weak, nonatomic) AppDelegate *appDelegate;

@property (weak, nonatomic) NSLayoutConstraint *viewTopConstraint;

@end

@implementation DetailScrollViewController{
    UIActivityIndicatorView *tableViewHeaderActivityIndicator_;
    UIImage *previewImage_;
    BOOL isFirstAppearance_;
    DescriptionParser *descriptionParser_;
    UIView *navBackgroundView_;
    UIView *backgroundView_;
    UIView *viewAboveBackground_;
    UIView *viewBelowBackground_;
    UIPanGestureRecognizer *detailsPanRecognizer_;
    CFTimeInterval timeLastDetailsPan_;
    CFTimeInterval timeLastCategoryPan_;
}

#pragma mark - Init / dealloc

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        descriptionParser_ = [[DescriptionParser alloc] init];
        isFirstAppearance_ = YES;
        navBackgroundView_ = nil;
        viewAboveBackground_ = nil;
        viewBelowBackground_ = nil;
        self.categoriesNeedToBeRefreshed = NO;
        timeLastDetailsPan_ = CACurrentMediaTime();
        timeLastCategoryPan_ = CACurrentMediaTime();
    }
    return self;
}

-(void)dealloc
{
	[self.view  removeObserver:self forKeyPath:@"center"];
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - View lifecycle

/**
 * View has loaded.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.translatesAutoresizingMaskIntoConstraints = NO;

    previewImage_ = nil;
    
    // Get the app delegate so the loading indicator may be accessed
	self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    // l10n
    self.title = [MWMessage forKey:@"details-title"].text;
    self.titleLabel.text = [MWMessage forKey:@"details-title-label"].text;
    
    UIColor *placeholderTextColor = [UIColor whiteColor];
    self.titleTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:
                                                 [MWMessage forKey:@"details-title-placeholder"].text
                                                                                attributes:
                                                 @{NSForegroundColorAttributeName: placeholderTextColor}
                                                 ];

    self.descriptionLabel.text = [MWMessage forKey:@"details-description-label"].text;
    self.descriptionPlaceholder.text = [MWMessage forKey:@"details-description-placeholder"].text;
    self.descriptionPlaceholder.textColor = placeholderTextColor;
    
    self.licenseLabel.text = [MWMessage forKey:@"details-license-label"].text;
    self.categoryLabel.text = [MWMessage forKey:@"details-category-label"].text;
    
    self.descriptionTextView.backgroundColor = DETAIL_EDITABLE_TEXTBOX_BACKGROUND_COLOR;
    self.descriptionTextLabel.backgroundColor = [UIColor clearColor];
    self.descriptionTextLabel.borderColor = [UIColor clearColor];
    self.descriptionTextLabel.paddingColor = DETAIL_NON_EDITABLE_TEXTBOX_BACKGROUND_COLOR;
    [self.descriptionTextLabel setPaddingInsets:DETAIL_DESCRIPTION_PADDING_INSET];
    
    self.titleTextField.backgroundColor = DETAIL_EDITABLE_TEXTBOX_BACKGROUND_COLOR;
    self.titleTextLabel.backgroundColor = [UIColor clearColor];
    self.titleTextLabel.borderColor = [UIColor clearColor];
    self.titleTextLabel.paddingColor = DETAIL_NON_EDITABLE_TEXTBOX_BACKGROUND_COLOR;
    [self.titleTextLabel setPaddingInsets:DETAIL_TITLE_PADDING_INSET];

    // Add a bit of left and right padding to the text box
    self.titleTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 20)];
    self.titleTextField.leftViewMode = UITextFieldViewModeAlways;
    self.titleTextField.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 20)];
    self.titleTextField.rightViewMode = UITextFieldViewModeAlways;

	self.titleTextField.textColor = DETAIL_EDITABLE_TEXTBOX_TEXT_COLOR;
	self.descriptionTextView.textColor = DETAIL_EDITABLE_TEXTBOX_TEXT_COLOR;

    // Set delegates so we know when fields change...
    self.titleTextField.delegate = self;
    self.descriptionTextView.delegate = self;
    
    // Make the title text box keyboard "Done" button dismiss the keyboard
    [self.titleTextField setReturnKeyType:UIReturnKeyDone];
    [self.titleTextField addTarget:self.descriptionTextView action:@selector(becomeFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    
    // Make taps to title or description labels cause their respective text boxes to receive focus
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusOnTitleTextField)];
    [self.titleContainer addGestureRecognizer:tapGesture];
    
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusOnDescriptionTextView)];
    [self.descriptionContainer addGestureRecognizer:tapGesture];

    self.licenseNameLabel.textColor = [UIColor whiteColor];
    
    self.descriptionLabel.textColor = DETAIL_LABEL_COLOR;
    self.titleLabel.textColor = DETAIL_LABEL_COLOR;
    self.licenseLabel.textColor = DETAIL_LABEL_COLOR;
    self.categoryLabel.textColor = DETAIL_LABEL_COLOR;

    [self.view setMultipleTouchEnabled:NO];

    self.view.opaque = NO;
    self.view.backgroundColor = [UIColor clearColor];

    self.view.layer.cornerRadius = DETAIL_BORDER_RADIUS;
    self.view.layer.borderWidth = DETAIL_BORDER_WIDTH;
    self.view.layer.borderColor = [DETAIL_BORDER_COLOR CGColor];

    // Allow the gradient above the table and the filler below the table to be seen
    self.view.clipsToBounds = NO;
 
    // Keep self.view the same size as self.scrollContainer so the pan gesture recognizer attached to self.view
    // will cover the same area as self.scrollContainer
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.scrollContainer
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1.0
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.scrollContainer
                                                          attribute:NSLayoutAttributeHeight
                                                         multiplier:1.0
                                                           constant:0]];

    [self configureBackgrounds];

    // Enable vertical sliding
    detailsPanRecognizer_ = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDetailsPan:)];
    detailsPanRecognizer_.delegate = self;
    [self.view addGestureRecognizer:detailsPanRecognizer_];

    // Keep track of sliding
    [self.view addObserver:self forKeyPath:@"center" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionPrior context:NULL];

    self.view.backgroundColor = [UIColor clearColor];
    self.scrollContainer.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
    UIColor *containerColor = [UIColor colorWithWhite:0.6f alpha:0.15f];
    self.titleContainer.backgroundColor = containerColor;
    self.descriptionContainer.backgroundColor = containerColor;
    self.licenseContainer.backgroundColor = containerColor;
    self.categoryContainer.backgroundColor = containerColor;
    
    [self configureForSelectedRecord];
    [self configureHideKeyboardButton];

    //[self.view randomlyColorSubviews];
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
    
    self.viewTopConstraint = [NSLayoutConstraint constraintWithItem:self.view
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view.superview
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0];
    [self.view.superview addConstraint:self.viewTopConstraint];
    
    [self.view.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                                    attribute:NSLayoutAttributeCenterX
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.view.superview
                                                                    attribute:NSLayoutAttributeCenterX
                                                                   multiplier:1.0
                                                                     constant:0]];
    
    [self.view.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.scrollContainer
                                                                   attribute:NSLayoutAttributeWidth
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view.superview
                                                                   attribute:NSLayoutAttributeWidth
                                                                  multiplier:1.0
                                                                    constant:0]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

	// Only move details to bottom if coming from my uploads (not categories, license etc...)
	if(isFirstAppearance_){

        // Move details to docking position at bottom of screen
        [self moveDetailsToDock];
        
        [self.delegate clearOverlay];
	}

    if(!self.selectedRecord.complete.boolValue){
        [self addNavBarBackgroundViewForTouchDetection];
    }
    
    // Ensure nav bar isn't being underlapped by details
    // (needed if details pushed another view controller while details was scrolled so far up that
    // it had caused the nav bar to be hidden - without this extra call to "makeNavBarRunAwayFromDetails"
    // here, when that pushed view gets popped, the nav would overlap the details)
    [self makeNavBarRunAwayFromDetails];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    isFirstAppearance_ = NO;

    if (self.categoriesNeedToBeRefreshed) {
        self.categoriesNeedToBeRefreshed = NO;
        FileUpload *record = self.selectedRecord;
        if (record != nil) {
            self.categoryList = [record.categoryList mutableCopy];
            [self updateCategoryContainer];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [navBackgroundView_ removeFromSuperview];
    [self hideKeyboard];
    [super viewWillDisappear:animated];

    // Ensure the nav bar is visible
    // (needed because "makeNavBarRunAwayFromDetails" method could have hidden the nav bar)
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

#pragma mark - Keyboard

-(void) configureHideKeyboardButton
{
    // Add a "hide keyboard" button above the keyboard (when the description box has the focus and the
    // keyboard is visible). Did this so multi-line descriptions could still be entered *and* the
    // keyboard could still be dismissed (otherwise the "return" button would have to be made into a
    // "Done" button which would mean line breaks could not be entered)
    
    // Note: Only show the "hide keyboard" button for new images as existing image descriptions are
    // read-only for now
    if ((!self.selectedRecord.complete.boolValue) && (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)){
        UIButton *hideKeyboardButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [hideKeyboardButton addTarget:self action:@selector(hideKeyboardAccessoryViewTapped) forControlEvents:UIControlEventTouchDown];

        [hideKeyboardButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [hideKeyboardButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
        hideKeyboardButton.backgroundColor = [UIColor colorWithRed:0.56 green:0.59 blue:0.63 alpha:0.95];
        [hideKeyboardButton.titleLabel setShadowColor:[UIColor blackColor]];
        [hideKeyboardButton.titleLabel setShadowOffset: CGSizeMake(0, -1)];
        
        [hideKeyboardButton setTitle:[MWMessage forKey:@"details-hide-keyboard"].text forState:UIControlStateNormal];
        hideKeyboardButton.frame = CGRectMake(80.0, 210.0, 160.0, 28.0);
        self.descriptionTextView.inputAccessoryView = hideKeyboardButton;
    }
}

#pragma mark - Gestures

-(void)handleDetailsPan:(UIPanGestureRecognizer *)recognizer
{
    static CGPoint originalCenter;
    static CGPoint originalTouch;
    
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        originalCenter = recognizer.view.center;
        originalTouch = [recognizer locationInView:recognizer.view.superview];
        //recognizer.view.layer.shouldRasterize = YES;
    }
    if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        CGPoint translate = [recognizer translationInView:recognizer.view.superview];
        translate.x = 0; // Don't move sideways
        
        CGPoint currentTouch = [recognizer locationInView:recognizer.view.superview];
        CFTimeInterval elapsedTime = CACurrentMediaTime() - timeLastCategoryPan_;
        if ((elapsedTime > 0.25) && (fabsf(currentTouch.y - originalTouch.y) > fabsf(currentTouch.x - originalTouch.x))) {
            // If enough time has elapsed since timeLastCategoryPan_ and there's been more vertical than horizontal touch movement
            // then it's safe to carry on and allow details to pan vertically
            timeLastDetailsPan_ = CACurrentMediaTime();
        }else{
            translate.y = 0;
        }
        
        recognizer.view.center = CGPointMake(originalCenter.x + translate.x, originalCenter.y + translate.y);
    }
    if (recognizer.state == UIGestureRecognizerStateEnded ||
        recognizer.state == UIGestureRecognizerStateFailed ||
        recognizer.state == UIGestureRecognizerStateCancelled)
    {
        // Ensure the top constraint is updated to reflect the newly scrolled-to-position.
        // Needed otherwise things like ensureScrollingDoesNotExceedThreshold only work the
        // first time. This is because calls to "layoutIfNeeded" only result if the layout
        // being updated if it sees that something has changed. If this constraint is not
        // updated after scrolling, nothing will appear to have changed. To see an example
        // of the issue, comment out the line below. Then load the details page and drag
        // the details slider up until its bottom is visible. When released it will snap
        // so back its bottom is at the bottom of the screen (thanks to the call to the
        // "ensureScrollingDoesNotExceedThreshold" below). Now do so a second time and it
        // won't snap back.
        self.viewTopConstraint.constant = recognizer.view.frame.origin.y;
    
        // Ensure the table isn't scrolled so far down or up
        [self ensureScrollingDoesNotExceedThreshold];
        
        timeLastDetailsPan_ = CACurrentMediaTime();
    }
}

#pragma mark - Selected record

-(void)configureForSelectedRecord
{
    // Load up the selected record
    FileUpload *record = self.selectedRecord;
    if (record != nil) {
        self.categoryList = [record.categoryList mutableCopy];
        self.titleTextField.text = record.title;
        self.titleTextLabel.text = record.title;
        self.descriptionTextView.text = record.desc;
        self.descriptionTextLabel.text = record.desc;
        self.descriptionPlaceholder.hidden = (record.desc.length > 0);
        self.categoryListLabel.text = [self categoryShortList];

        // Get categories and description
        if (record.complete.boolValue) {
            self.descriptionTextLabel.text = [MWMessage forKey:@"details-description-loading"].text;
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self getPreviouslySavedDescriptionForRecord:record];
                [self getPreviouslySavedCategoriesForRecord:record];
            });
        }else{
            [self updateCategoryContainer];
        }

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (record.complete.boolValue) {
                // Completed upload...
                self.titleTextField.enabled = NO;
                self.titleTextField.hidden = YES;
                self.titleTextLabel.hidden = NO;
                self.descriptionTextView.editable = NO;
                self.descriptionTextView.hidden = YES;
                [self.descriptionTextView removeConstraint:self.descriptionTextViewHeightConstraint];
                [self.titleTextField removeConstraint:self.titleTextFieldHeightConstraint];
                
                self.descriptionTextLabel.hidden = NO;
                self.deleteButton.enabled = NO; // fixme in future, support deleting uploaded items
                self.actionButton.enabled = YES; // open link or share on the web
                self.uploadButton.enabled = NO; // fixme either hide or replace with action button?
                
                self.descriptionPlaceholder.hidden = YES;

                // Make description read-only for now
                self.descriptionTextView.userInteractionEnabled = NO;
                self.descriptionLabel.hidden = NO;
                
                // fixme: load license info from wiki page
                self.licenseLabel.hidden = YES;
                self.licenseNameLabel.hidden = YES;
                self.ccByImage.hidden = YES;
                self.ccSaImage.hidden = YES;

                // either use HTML http://commons.wikimedia.org/wiki/Commons:Machine-readable_data
                // or pick apart the standard templates
            } else {
                // Locally queued file...
                self.titleTextField.enabled = YES;
                self.titleTextField.hidden = NO;
                self.titleTextLabel.hidden = YES;
                self.descriptionTextView.editable = YES;
                [self.descriptionTextView addConstraint:self.descriptionTextViewHeightConstraint];
                [self.titleTextField addConstraint:self.titleTextFieldHeightConstraint];

                self.descriptionTextView.hidden = NO;
                self.descriptionTextLabel.hidden = YES;
                self.deleteButton.enabled = (record.progress.floatValue == 0.0f); // don't allow delete _during_ upload
                self.actionButton.enabled = NO;
                
                self.descriptionLabel.hidden = NO;
                self.descriptionPlaceholder.hidden = (record.desc.length > 0);
                self.licenseLabel.hidden = NO;
                self.licenseNameLabel.hidden = NO;
                self.ccByImage.hidden = NO;
                self.ccSaImage.hidden = NO;
                
                [self updateUploadButton];
                [self updateShareButton];
            }
        });
    
    } else {
        NSLog(@"This isn't right, have no selected record in detail view");
    }
}

#pragma mark - Buttons

- (void)updateUploadButton
{
    FileUpload *record = self.selectedRecord;
    if (record != nil && !record.complete.boolValue) {
        self.uploadButton.enabled = record.title.length > 0 &&
        record.desc.length > 0;
    }
}

- (void)updateShareButton
{
    FileUpload *record = self.selectedRecord;
    if (record != nil && !record.complete.boolValue) {
        self.shareButton.enabled = record.title.length > 0 &&
        record.desc.length > 0;
    }
}

- (IBAction)deleteButtonPushed:(id)sender {
    CommonsApp *app = CommonsApp.singleton;
    // Informs the My Uploads VC that it needs to delete a record after it's view did appear.
    // (gives autolayout a chance to do it's thing before the record is removed)
    app.recordToDelete = self.selectedRecord;
    self.selectedRecord = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)openLicense
{
    [CommonsApp.singleton openURLWithDefaultBrowser:[NSURL URLWithString:URL_IMAGE_LICENSE]];
}

- (IBAction)shareButtonPushed:(id)sender
{
    FileUpload *record = self.selectedRecord;
    if (record == nil) {
        NSLog(@"No image to share. No record.");
        return;
    }
    
    if (!record.complete.boolValue) {
        NSLog(@"No image to share. Not complete.");
        return;
    }
    
    // Could display more than just the loading indicator at this point - could
    // display message saying "Retrieving full resolution image for sharing" or
    // something similar
    [self.appDelegate.loadingIndicator show];
        
    // Fetch cached or internet image at standard size
    // FIXME: initialize fetching later on while the user chooses an action
    MWPromise *fetch = [CommonsApp.singleton fetchWikiImage:record.title size:[CommonsApp.singleton getFullSizedImageSize] withQueuePriority:NSOperationQueuePriorityHigh];
    
    [fetch done:^(UIImage *image) {

        // Get the wiki url for the image
        NSString *pageTitle = [@"File:" stringByAppendingString:self.selectedRecord.title];
        NSURL *wikiUrl = [CommonsApp.singleton URLForWikiPage:pageTitle];
        
        // Present the sharing interface for the image itself and its wiki url
        OpenInBrowserActivity *openInSafariActivity = [[OpenInBrowserActivity alloc] init];
        self.shareActivityViewController = [[UIActivityViewController alloc]
                                            initWithActivityItems:@[image, wikiUrl]
                                            applicationActivities:@[openInSafariActivity]
                                            ];

        [self toggle];

        [self presentViewController:self.shareActivityViewController animated:YES completion:^{
            [self.appDelegate.loadingIndicator hide];
        }];

        __weak DetailScrollViewController *weakSelf = self;

        [self.shareActivityViewController setCompletionHandler:^(NSString *activityType, BOOL completed) {
            [weakSelf toggle];
        }];
    }];
    [fetch fail:^(NSError *error) {
        NSLog(@"Failed to obtain image for sharing: %@", [error localizedDescription]);
    }];
    [fetch always:^(id obj) {
        [self.appDelegate.loadingIndicator hide];
    }];
}

#pragma mark - Nav bar

-(void)addNavBarBackgroundViewForTouchDetection
{
    CGRect f = self.navigationController.navigationBar.bounds;
    // Set size to just encompass the upload button in the center of the screen
    f = CGRectInset(f, (f.size.width / 2.0f) - 60.0f, 0.0f);
    navBackgroundView_ = [[UIView alloc] initWithFrame:f];
    navBackgroundView_.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.0f];
    navBackgroundView_.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
    UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleLeftMargin |
    UIViewAutoresizingFlexibleTopMargin |
    UIViewAutoresizingFlexibleHeight |
    UIViewAutoresizingFlexibleBottomMargin;
    [self.navigationController.navigationBar addSubview:navBackgroundView_];
    [self.navigationController.navigationBar sendSubviewToBack:navBackgroundView_];
    navBackgroundView_.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(navBackgroundViewTap:)];
    tapGesture.cancelsTouchesInView = NO;
    [navBackgroundView_ addGestureRecognizer:tapGesture];
}

-(void)navBackgroundViewTap:(UITapGestureRecognizer *)recognizer
{
    // If user taps disabled upload button or the nav bar this causes the details table to slide up
    // Nice prompt to remind user to enter title and description
    if ([CommonsApp.singleton getTrimmedString:self.titleTextField.text].length == 0) {
        [self focusOnTitleTextField];
    }else if ([CommonsApp.singleton getTrimmedString:self.descriptionTextView.text].length == 0) {
        [self focusOnDescriptionTextView];
    }
}

-(void)clearNavBarPrompt
{
    self.delegate.navigationItem.prompt = nil;
}

-(void)makeNavBarRunAwayFromDetails
{
    // Calling "setNavigationBarHidden:" below causes subviews to be laid out. If the view was being
    // dragged when this method is called this will cause the layout system to use the last value it
    // had for self.viewTopConstraint.constant, which, during drag, doesn't get updated until the drag
    // ends, so the pre-drag value is seen and the layout system makes self.view jump down to this
    // position, which is not what we want at all. To prevent this, update self.viewTopConstraint.constant
    // here. See the note in "handleDetailsPan:" concerning updating "self.viewTopConstraint.constant"
    // for more details about the issue. (To reproduce the bug, use iOS 7, comment out the line below and
    // drag the details page slider up until the top of it hits the navigation bar.)
    self.viewTopConstraint.constant = self.view.frame.origin.y;

    // Prevent details from underlapping nav bar by hiding nav bar when details scrolled up so
    // far that underlap would occur. And when details scrolled back down make nav bar re-appear.
    if ([self verticalDistanceFromNavBar] < 0.0f) {
        if (!self.navigationController.navigationBarHidden) {
            [self.navigationController setNavigationBarHidden:YES animated:YES];
        }
    }else{
        if (self.navigationController.navigationBarHidden) {
            [self.navigationController setNavigationBarHidden:NO animated:YES];
        }
    }
}

-(float)verticalDistanceFromNavBar
{
	return self.view.frame.origin.y - self.navigationController.navigationBar.frame.size.height;
}












#pragma mark - To do - from table code
// remove prepareForSegue and other cruft

// Hide only the license row if viewing details of already-uploaded image
//        if (self.selectedRecord.complete.boolValue) {
//            // Hide description row if none found
//            return (self.descriptionTextView.text.length == 0) ? 1 : 2;
//        }

// Categories - show loading message while uploading already uploaded img categories
//        if (self.selectedRecord.complete.boolValue) {
//            // If no categories show one cell so it can contain "Loading..." message, else hide the add button
//            // for already uploaded images as categories are read-only for them for now
//            return (self.categoryList.count == 0) ? 1 : self.categoryList.count;
//        }

// Categories title
//      [MWMessage forKey:@"details-category-label"].text;


// Show add categories button for yet-to-be-uploaded images


//        if (self.selectedRecord.complete.boolValue) {
// Show "Loading..." row if no categories
//            if(self.categoryList.count == 0){
//                cell = [tableView dequeueReusableCellWithIdentifier:@"CategoryCell"];
//                cell.accessoryType = UITableViewCellAccessoryNone;
//                cell.userInteractionEnabled = NO;
//                cell.textLabel.text = [MWMessage forKey:@"details-category-loading"].text;
//                cell.textLabel.backgroundColor = [UIColor clearColor];
//				cell.selectionStyle = UITableViewCellSelectionStyleNone;
//                return cell;
//            }
//        }


//        if (indexPath.row < self.categoryList.count) {
//            cell = [tableView dequeueReusableCellWithIdentifier:@"CategoryCell"];
//			cell.selectionStyle = UITableViewCellSelectionStyleNone;
//            // Make categories read-only for now
//            if (self.selectedRecord.complete.boolValue) {
//                cell.accessoryType = UITableViewCellAccessoryNone;
//                cell.userInteractionEnabled = NO;
//            }
//            
//            cell.textLabel.text = self.categoryList[indexPath.row];
//        } else {
//            cell = [tableView dequeueReusableCellWithIdentifier:@"AddCategoryCell"];
//            cell.textLabel.text = [MWMessage forKey:@"catadd-title"].text;
//            cell.textLabel.textColor = DETAIL_LABEL_COLOR;
//        }



//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (indexPath.section == 0) {
//        // Static section already handled by storyboard segues.
//    } else if (indexPath.section == 1) {
//        if (indexPath.row < self.categoryList.count) {
//            // Segue isn't connected due to nib fun. :P
//            [self performSegueWithIdentifier: @"CategoryDetailSegue" sender: self];
//        } else {
//            // 'Add category...' cell button
//            // Segue isn't connected due to nib fun. :P
//            [self performSegueWithIdentifier: @"AddCategorySegue" sender: self];
//        }
//    }
//}




//-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
//{
//    if (indexPath.section == 1 && indexPath.row < self.categoryList.count) {
//        NSString *cat = self.categoryList[indexPath.row];
//        NSString *encCat = [cat stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//        NSString *link = [NSString stringWithFormat:@"https://commons.m.wikimedia.org/wiki/Category:%@", encCat];
//        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link]];
//    }
//}









#pragma mark - Focus to box when title or description label tapped
- (void)focusOnTitleTextField
{
    if (!self.titleTextField.enabled) return;
    [self.titleTextField becomeFirstResponder];
}

- (void)focusOnDescriptionTextView
{
    if (!self.descriptionTextView.editable) return;
    [self.descriptionTextView becomeFirstResponder];
}

#pragma mark - Repositioning for keyboard appearance

- (void)hideKeyboardAccessoryViewTapped
{
    [self hideKeyboard];
    // When the description field is being edited and the "hide keyboard" button is pressed
    // the nav bar needs to be revealed so the "upload" button is visible
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self scrollToTopBeneathNavBarAfterDelay:0.0f then:nil];
}

- (void)hideKeyboard
{
	// Dismisses the keyboard
	[self.titleTextField resignFirstResponder];
	[self.descriptionTextView resignFirstResponder];
}

#pragma mark - Text fields

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // When the title box receives focus scroll it to the top of the table view to ensure the keyboard
    // isn't hiding it
    [self scrollViewAboveKeyboard:self.titleLabel];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    // When the description box receives focus scroll it to the top of the table view to ensure the keyboard
    // isn't hiding it
    [self scrollViewAboveKeyboard:self.descriptionLabel];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    CommonsApp *app = CommonsApp.singleton;
    FileUpload *record = self.selectedRecord;
    NSLog(@"setting title: %@", self.titleTextField.text);
    record.title = self.titleTextField.text;
    [app saveData];
    [self updateUploadButton];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    CommonsApp *app = CommonsApp.singleton;
    [app saveData];
}

- (void)textViewDidChange:(UITextView *)textView
{
    self.descriptionPlaceholder.hidden = (textView.text.length > 0);

    FileUpload *record = self.selectedRecord;
    NSLog(@"setting desc: %@", self.descriptionTextView.text);
    record.desc = self.descriptionTextView.text;
    [self updateUploadButton];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"AddCategorySegue"]) {
        if (self.selectedRecord) {
            CategorySearchTableViewController *catVC = [segue destinationViewController];

            catVC.title = [MWMessage forKey:@"catadd-title"].text;
            
            catVC.selectedRecord = self.selectedRecord;
        }
    } else if ([segue.identifier isEqualToString:@"CategoryDetailSegue"]) {
        if (self.selectedRecord) {
            CategoryDetailTableViewController *view = [segue destinationViewController];
            view.selectedRecord = self.selectedRecord;
//            view.category = self.categoryList[self.tableView.indexPathForSelectedRow.row];
        }
    }
    
}

#pragma mark - Description retrieval

- (void)getPreviouslySavedDescriptionForRecord:(FileUpload *)record
{
    CommonsApp *app = CommonsApp.singleton;
    MWApi *api = [app startApi];
    NSMutableDictionary *params = [@{
                                   @"action": @"query",
                                   @"prop": @"revisions",
                                   @"rvprop": @"content",
                                   @"rvparse": @"1",
                                   @"rvlimit": @"1",
                                   @"rvgeneratexml": @"1",
                                   @"titles": [@"File:" stringByAppendingString:record.title],
                                   
                                   // Uncomment to test image w/multiple descriptions - see console for output (comment out the line above when doing so)
                                   // @"titles": [@"File:" stringByAppendingString:@"2011-08-01 10-31-42 Switzerland Segl-Maria.jpg"],
                                   
                                   } mutableCopy];
    
    MWPromise *req = [api getRequest:params];
    
    __weak UITextView *weakDescriptionTextView = self.descriptionTextView;
    __weak UILabelDynamicHeight *weakDescriptionTextLabel = self.descriptionTextLabel;
    
    [req done:^(NSDictionary *result) {
        for (NSString *page in result[@"query"][@"pages"]) {
            for (NSDictionary *category in result[@"query"][@"pages"][page][@"revisions"]) {
                //NSMutableString *pageHTML = [category[@"*"] mutableCopy];
                
                descriptionParser_.xml = category[@"parsetree"];
                descriptionParser_.done = ^(NSDictionary *descriptions){
                    
                    //for (NSString *description in descriptions) {
                    //    NSLog(@"[%@] description = %@", description, descriptions[description]);
                    //}
                    
                    // Show description for locale
                    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
                    language = [MWI18N filterLanguage:language];
                    weakDescriptionTextView.text = ([descriptions objectForKey:language]) ? descriptions[language] : descriptions[@"en"];
                    // reloadData so description cell can be resized according to the retrieved description's text height
//                    [weakTableView reloadData];
                };
                [descriptionParser_ parse];
            }
        }
    }];
    
    [req always:^(NSDictionary *result) {
        if ([weakDescriptionTextView.text isEqualToString: [MWMessage forKey:@"details-description-loading"].text]){
            weakDescriptionTextView.text = [MWMessage forKey:@"details-description-none-found"].text;
        }
        weakDescriptionTextLabel.text = weakDescriptionTextView.text;
    }];
}

#pragma mark - Category retrieval

- (void)getPreviouslySavedCategoriesForRecord:(FileUpload *)record
{
    NSMutableArray *previouslySavedCategories = [[NSMutableArray alloc] init];
    CommonsApp *app = CommonsApp.singleton;
    MWApi *api = [app startApi];
    NSMutableDictionary *params = [@{
                                   @"action": @"query",
                                   @"prop": @"categories",
                                   @"clshow": @"!hidden",
                                   @"titles": [@"File:" stringByAppendingString:record.title],
                                   // @"titles": [@"File:" stringByAppendingString:@"2011-08-01 10-31-42 Switzerland Segl-Maria.jpg"],
                                   } mutableCopy];
    
    MWPromise *req = [api getRequest:params];
    
    // While retrieving categories should change the "Add category..." text to say "Getting categories" or some such,
    // then in "always:" callback change it back to "Add category..."
    
    [req done:^(NSDictionary *result) {
        for (NSString *page in result[@"query"][@"pages"]) {
            for (NSDictionary *category in result[@"query"][@"pages"][page][@"categories"]) {
                NSMutableString *categoryTitle = [category[@"title"] mutableCopy];
                
                // Remove "Category:" prefix from category title
                NSError *error = NULL;
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^Category:" options:NSRegularExpressionCaseInsensitive error:&error];
                [regex replaceMatchesInString:categoryTitle options:0 range:NSMakeRange(0, [categoryTitle length]) withTemplate:@""];
                
                [previouslySavedCategories addObject:categoryTitle];
            }
        }
        
        if (self.selectedRecord.complete.boolValue) {
            if(previouslySavedCategories.count == 0) [previouslySavedCategories addObject:[MWMessage forKey:@"details-category-none-found"].text];
        }
        
        // Make interface use the new category list
        self.categoryList = previouslySavedCategories;
        [self updateCategoryContainer];

        self.selectedRecord.categories = [self.categoryList componentsJoinedByString:@"|"];
        self.categoryListLabel.text = [self categoryShortList];
//        [self.tableView reloadData];
    }];
}

#pragma mark - Category layout

-(void)updateCategoryContainer
{
    // Updates categoryContainer to have label for each entry found in self.categoryList.
    // Constrains all categoryContainer subviews as well.

    NSMutableArray *categoryLabels = [[NSMutableArray alloc] init];

    // Every view which gets constrained by this method is also created by this method
    // with the exeption of self.categoryLabel. This means views created here can be
    // constrained here without having to worry about a new constraint conflicting with
    // an old pre-existing constraint. But since self.categoryLabel isn't created here
    // it may have constraints left-over from last time this method was invoked. Since
    // constraints are usually added to a view's superview (or above), simply calling
    // "[view removeConstraints:view.constraints]" won't get rid of them and it's a
    // pain to have to go to the view's superview and inspect its constraints for those
    // affecting view, so a quick way to achieve the same result is to remove view from
    // it's superview, which causes constraints related to view to be removed, then just
    // re-add view to superview. (Note: added removal of all categoryContainer subviews to
    // ensure subsequent calls to this method won't result in duplicate category labels)
    __strong UIView *label = self.categoryLabel;
    UIView *sv = label.superview;
    for (UIView *subview in [self.categoryContainer.subviews copy]) {
        [subview removeFromSuperview];
    }
    [sv addSubview:label];

    // Add entry for "Add Category" to end of categoryListCopy. This will cause
    // the "Add Category" button to be made and constrained by hijacking the
    // category layout code below.
    NSMutableArray *categoryListCopy = [[[self.categoryList reverseObjectEnumerator] allObjects] mutableCopy];
    FileUpload *record = self.selectedRecord;
    if (record != nil && !record.complete.boolValue) {
        [categoryListCopy insertObject:[MWMessage forKey:@"catadd-title"].text atIndex:0];
    }

    // Create labels for categories, add them to the categoryContainer, and remember
    // them in a categoryLabels array
    for (NSString *categoryString in categoryListCopy) {
        UILabelDynamicHeight *label = [[UILabelDynamicHeight alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.text = categoryString;
        [label setFont:[UIFont systemFontOfSize:14.0f]];
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        label.borderColor = [UIColor clearColor];
        label.paddingColor = DETAIL_NON_EDITABLE_TEXTBOX_BACKGROUND_COLOR;
        [label setPaddingInsets:DETAIL_CATEGORY_PADDING_INSET];
        [self.categoryContainer addSubview:label];
        [categoryLabels addObject:label];

        // Determine if the current label is the "Add Category" label. If so
        // adjust it as needed to respond to touch.
        if (record != nil && !record.complete.boolValue) {
            if (categoryString == [categoryListCopy firstObject]){
                //label.backgroundColor = [UIColor redColor];
                UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addCategoryTapped)];
                [label addGestureRecognizer:tapGesture];
                label.textAlignment = NSTextAlignmentCenter;
                label.paddingColor = DETAIL_EDITABLE_TEXTBOX_BACKGROUND_COLOR;
            }else{
                // Else it's not the "Add Category" button so it's an actual category label.
                label.userInteractionEnabled = YES;
                UIPanGestureRecognizer *catPanRecognizer_ = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleCategoryPan:)];
                catPanRecognizer_.delegate = self;
                [label addGestureRecognizer:catPanRecognizer_];
                
                [self addHamburgerToLabel:label];
            }
        }
    }

    // Create autolayout format string for even vertically spacing of
    // categoryContainer's subviews. Also create views dictionary with
    // entry for each categoryContainer subview (use pointer address
    // cast to string for category label identifiers)
    NSMutableString *visualFormatString = [@"V:|-[categoryLabel]-" mutableCopy];
    NSMutableDictionary *views = [[NSMutableDictionary alloc] init];
    [views setObject:self.categoryLabel forKey:@"categoryLabel"];
    for (UILabel *label in categoryLabels) {
        NSString *pointerString = [NSString stringWithFormat: @"view_%p", label];
        [visualFormatString appendString:[NSString stringWithFormat: @"[%@]-", pointerString]];
        [views setObject:label forKey:pointerString];
    }
    [visualFormatString appendString:@"|"];
    NSLog(@"\n\n\nvisual format string:\n\n %@\n\nview dictionary:\n\n%@\n\n\n", visualFormatString, views);

    // Add space between sides of categoryLabel and categoryContainer
    [self.categoryContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[categoryLabel]-|" options:0 metrics:nil views:@{@"categoryLabel": self.categoryLabel}]];

    if (categoryListCopy.count > 0) {
        // Add space between sides of labels and categoryContainer
        for (UILabel *l in categoryLabels) {
            [self.categoryContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[label]-|" options:0 metrics:nil views:@{@"label": l}]];
        }
        // Add even vertical space between all subviews of categoryContainer
        [self.categoryContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:visualFormatString options:0 metrics:nil views:views]];
    }else{
        // No categories found, so add space between the top and bottom of categoryLabel and categoryContainer
        [self.categoryContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[categoryLabel]-|" options:0 metrics:nil views:@{@"categoryLabel": self.categoryLabel}]];
    }

    [self.categoryContainer layoutIfNeeded];
}

- (NSString *)categoryShortList
{
    // Assume the list will be cropped off in the label if it's long. :)
    NSArray *cats = self.selectedRecord.categoryList;
    if (cats.count == 0) {
        return [MWMessage forKey:@"details-category-select"].text;
    } else {
        return [cats componentsJoinedByString:@", "];
    }
}

-(void)addHamburgerToLabel:(UILabelDynamicHeight *)label
{
    UIImageView *burger = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"categoryHamburger.png"]];
    burger.translatesAutoresizingMaskIntoConstraints = NO;
    [label.paddingView addSubview: burger];
    [label.paddingView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[burger]|"
                                                                              options:0
                                                                              metrics:nil
                                                                                views:@{@"burger": burger}
                                       ]];
    [label.paddingView addConstraint:[NSLayoutConstraint constraintWithItem:burger
                                                                  attribute:NSLayoutAttributeCenterY
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:label.paddingView
                                                                  attribute:NSLayoutAttributeCenterY
                                                                 multiplier:1.0
                                                                   constant:0]];
}

#pragma mark - Category swipe to delete

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

-(void)handleCategoryPan:(UIPanGestureRecognizer *)recognizer
{
    // The static dict is used because it is not guaranteed that a given call to the recognizer
    // will be from the same object. This approach makes category swipe-to-delete work multi-touch!
    static NSMutableDictionary *dict = nil;
    if (!dict) dict = [[NSMutableDictionary alloc] init];
    
    // key() retrieves the correct object handle
    NSString *(^key)() = ^(){
        return [NSString stringWithFormat: @"%p", recognizer.view];
    };
    
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        dict[key()] = @{
                        @"originalCenter": [NSValue valueWithCGPoint:recognizer.view.center],
                        @"originalTouch": [NSValue valueWithCGPoint:[recognizer locationInView:recognizer.view.superview]],
                        @"originalAlpha": @(recognizer.view.alpha)
                        };
    }
    if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        CGPoint translate = [recognizer translationInView:recognizer.view.superview];
        translate.y = 0; // Don't move vertically
        
        CGPoint currentTouch = [recognizer locationInView:recognizer.view.superview];
        CFTimeInterval elapsedTime = CACurrentMediaTime() - timeLastDetailsPan_;
        CGPoint originalTouch = [dict[key()][@"originalTouch"] CGPointValue];
        if ((elapsedTime > 0.5) && (fabsf(currentTouch.x - originalTouch.x) > fabsf(currentTouch.y - originalTouch.y))) {
            // If enough time has elapsed since timeLastDetailsPan_ and there's been more horizontal than vertical touch movement
            // then it's safe to carry on and allow category to pan horizontally
            timeLastCategoryPan_ = CACurrentMediaTime();
            
            float alpha = 1.5f - fabsf(translate.x / (recognizer.view.frame.size.width / 2.0f));
            //NSLog(@"alpha = %f", alpha);
            recognizer.view.alpha = alpha;
            
            translate.x = translate.x * 0.66f;
            
        }else{
            translate.x = 0;
        }
        
        CGPoint originalCenter = [dict[key()][@"originalCenter"] CGPointValue];
        recognizer.view.center = CGPointMake(originalCenter.x + translate.x, originalCenter.y + translate.y);
        
    }
    if (recognizer.state == UIGestureRecognizerStateEnded ||
        recognizer.state == UIGestureRecognizerStateFailed ||
        recognizer.state == UIGestureRecognizerStateCancelled)
    {
        //CGPoint velocity = [recognizer velocityInView:recognizer.view.superview];
        //NSLog(@"if fabsf(x velocity) is great here then delete = %@", NSStringFromCGPoint(velocity));

        if (recognizer.view.alpha < 0.18f) {
            [self deleteLabelsCategory:(UILabel *)recognizer.view];
        }
        
        CGPoint originalCenter = [dict[key()][@"originalCenter"] CGPointValue];
        recognizer.view.center = originalCenter;
        
        timeLastCategoryPan_ = CACurrentMediaTime();
        
        CGFloat originalAlpha = [dict[key()][@"originalAlpha"] floatValue];
        
        recognizer.view.alpha = originalAlpha;
        
        [dict removeObjectForKey:key()];
    }
}

-(void)deleteLabelsCategory:(UILabel *)label
{
    // Remove the label of the category to be deleted from self.selectedRecord.
    // Also adds proper constraints between the labels above and below the one
    // being deleted.
    UILabel *viewAbove = nil;
    UILabel *viewBelow = nil;
    for (NSLayoutConstraint *c in label.superview.constraints) {
        if ((c.firstItem == label)) {
            // Find the view above
            if((c.firstAttribute == NSLayoutAttributeTop) && (c.secondAttribute == NSLayoutAttributeBottom)){
                viewAbove = c.secondItem;
                NSLog(@"above text %@", viewAbove.text);
            }
        }
        if ((c.secondItem == label)) {
            // Find the view below
            if((c.firstAttribute == NSLayoutAttributeTop) && (c.secondAttribute == NSLayoutAttributeBottom)){
                viewBelow = c.firstItem;
                NSLog(@"below text %@", viewBelow.text);
            }
        }
    }
    
    if (viewAbove != nil) {
        UILabel *selectedLabel = (UILabel *)label;
        __strong NSString *category = selectedLabel.text;
        
        [label removeFromSuperview];

        if ((viewBelow != nil)) {
            [viewAbove.superview addConstraints:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"V:[viewAbove]-[viewBelow]"
                                                         options:0
                                                         metrics:0
                                                           views:NSDictionaryOfVariableBindings(viewAbove, viewBelow)]
            ];
        }else{
            [viewAbove.superview addConstraints:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"V:[viewAbove]-|"
                                                         options:0
                                                         metrics:0
                                                           views:NSDictionaryOfVariableBindings(viewAbove)]
            ];
        }
        [UIView animateWithDuration:0.2f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [viewAbove.superview layoutIfNeeded];
                         }
                         completion:^(BOOL finished){
                            [self.selectedRecord removeCategory:category];
                            [CommonsApp.singleton saveData];
                            [self scrollDownIfGapBeneathDetails];
                         }];
    }
}

#pragma mark - Category addition

-(void)addCategoryTapped
{
    CategorySearchTableViewController *catVC = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"CategorySearchTableViewController"];
    if (self.selectedRecord) {
        catVC.title = [MWMessage forKey:@"catadd-title"].text;
        catVC.selectedRecord = self.selectedRecord;
    }
    [self.navigationController pushViewController:catVC animated:YES];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"center"]) {
		// Keep track of sliding
        NSValue *new = [change valueForKey:@"new"];
        NSValue *old = [change valueForKey:@"old"];
        if (new && old) {
            if (![old isEqualToValue:new]) {
                [self reportDetailsScroll];
            }
        }
    }
}

#pragma mark - Rotation

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // If the keyboard was visible during rotation, scroll so the field being edited is near the top of the screen
    if (self.titleTextField.isFirstResponder) {
        [self scrollViewAboveKeyboard:self.titleLabel];
    }else if (self.descriptionTextView.isFirstResponder) {
        [self scrollViewAboveKeyboard:self.descriptionLabel];
    }else{
        [self ensureScrollingDoesNotExceedThreshold];
    }
}

#pragma mark - Details moving

-(void)moveDetailsToDock
{
    self.viewTopConstraint.constant = self.delegate.view.frame.size.height - DETAIL_DOCK_DISTANCE_FROM_BOTTOM;
    [self.view.superview layoutIfNeeded];
}

-(void)moveDetailsToBottom
{
    self.viewTopConstraint.constant = self.delegate.view.frame.size.height;
    [self.view.superview layoutIfNeeded];
}

-(void)moveDetailsBeneathNav
{
    self.viewTopConstraint.constant = self.navigationController.navigationBar.frame.size.height + self.navigationController.navigationBar.frame.origin.y;
    [self.view.superview layoutIfNeeded];
}

-(void)toggle
{
    // Hides/shows both the details view and the nav bar
    static float detailsY = 0.0f;
    static BOOL isAnimating = NO;
    if (isAnimating) return;
    if(self.navigationController.navigationBar.alpha == 1.0f){
        self.view.userInteractionEnabled = NO;
        self.navigationController.navigationBar.alpha = 0.0f;
        detailsY = self.view.frame.origin.y;
        float offset = self.view.superview.frame.size.height - detailsY;
        isAnimating = YES;
        [self scrollByAmount:offset withDuration:0.25f delay:0.0f options:UIViewAnimationCurveEaseOut useXF:NO then:^{
            self.view.alpha = 0.0f;
            isAnimating = NO;
        }];
        [self hideKeyboard];
    }else{
        self.view.userInteractionEnabled = YES;
        self.navigationController.navigationBar.alpha = 1.0f;
        self.view.alpha = 1.0f;
        float offset = self.view.frame.origin.y - detailsY;
        isAnimating = YES;
        [self scrollByAmount:-offset withDuration:0.25f delay:0.0f options:UIViewAnimationCurveEaseOut useXF:NO then:^{
          //[self ensureScrollingDoesNotExceedThreshold];
            isAnimating = NO;
        }];
    }
}

#pragma mark - Details scrolling

-(void)scrollByAmount:(float)amount withDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options useXF:(BOOL)useXF then:(void(^)(void))block
{
    [UIView animateWithDuration: duration
                          delay: delay
                        options: options
                     animations: ^{
						 //self.view.layer.shouldRasterize = YES;
                         if(useXF){
                             self.view.transform = CGAffineTransformTranslate(self.view.transform, 0, amount);
                         }else{
                             self.viewTopConstraint.constant = self.view.frame.origin.y + amount;
                             //NSLog(@"self.viewTopConstraint.constant = %f", self.viewTopConstraint.constant);
                             [self.view.superview layoutIfNeeded];
                         }
					 }
                     completion:^(BOOL finished){
						 //self.view.layer.shouldRasterize = NO;

						 if(block != nil) block();
                     }];
}

-(void)scrollToTopBeneathNavBarAfterDelay:(float)delay then:(void(^)(void))block
{
    [self scrollByAmount:-[self verticalDistanceFromNavBar] withDuration:0.25f delay:delay options:UIViewAnimationTransitionNone useXF:NO then:block];
}

-(void)scrollToPercentOfSuperview:(float)percent then:(void(^)(void))block
{
    float offset = ((percent / 100.0f) * self.view.superview.frame.size.height) - self.view.frame.origin.y;
    [self scrollByAmount:offset withDuration:0.25f delay:0.0f options:UIViewAnimationCurveEaseOut useXF:NO then:block];
}

- (void)scrollDownIfGapBeneathDetails
{
    // Scroll to eliminate any gap beneath the table and the bottom of the delegate's view
    float bottomGapHeight = [self getBottomGapHeight];
    if (bottomGapHeight > 0.0f) {
        //NSLog(@"bottomGapHeight = %f", bottomGapHeight);
        [self scrollByAmount:bottomGapHeight withDuration:0.25f delay:0.0f options:UIViewAnimationCurveEaseOut useXF:NO then:nil];
    }
}

- (void)scrollUpToDockIfNecessary
{
    float distance = [self distanceFromDock];
    if (distance > 0.0f) return;
    [self scrollByAmount:distance withDuration:0.25f delay:0.0f options:UIViewAnimationCurveEaseOut useXF:NO then:nil];
}

-(void)ensureScrollingDoesNotExceedThreshold
{
    // Ensure the table isn't scrolled so far down that it goes too far down offscreen
    [self scrollUpToDockIfNecessary];
    
    // Ensure the newly sized table isn't scrolled so far up that there's a gap beneath it
    [self scrollDownIfGapBeneathDetails];
}

- (BOOL)doesScrollingExceedThreshold
{
    if ([self getBottomGapHeight] > 0.0f) return YES;
    if ([self distanceFromDock] < 0.0f) return YES;
    return NO;
}

-(void)reportDetailsScroll
{
    static float lastScrollValue = 0.0f;
    float height = self.delegate.view.frame.size.height;

    float scrollValue = self.view.frame.origin.y / (height - DETAIL_DOCK_DISTANCE_FROM_BOTTOM);

    [self makeNavBarRunAwayFromDetails];

	float minChangeToReport = 0.025f;
    if (fabsf((scrollValue - lastScrollValue)) > minChangeToReport) {
        //NSLog(@"scrollValue = %f", scrollValue);
        scrollValue = MIN(scrollValue, 1.0f);
        scrollValue = MAX(scrollValue, 0.0f);
        lastScrollValue = scrollValue;
		self.detailsScrollNormal = scrollValue;
		[self.delegate setDetailsScrollNormal:scrollValue];

        // Set the background table alpha
        backgroundView_.alpha = MIN(DETAIL_TABLE_MAX_OVERLAY_ALPHA, 1.0f - scrollValue);

        // Clear out any prompt above the nav bar as soon as details scrolled
        [self clearNavBarPrompt];
    }
}

-(void)scrollViewAboveKeyboard:(UIView *)view
{
    [self scrollByAmount:[self getOffsetToMoveViewAboveKeyboard:view] withDuration:0.5f delay:0.0f options:UIViewAnimationCurveEaseOut useXF:NO then:nil];
}

-(float)getOffsetToMoveViewAboveKeyboard:(UIView *)view
{
    // Note: this offset is just a best guess near-ish the top of the screen.
    // Since the keyboard may be undocked and slid around and because the keyboard
    // size can change based on locale, it's perhaps not a good idea to try to
    // position actively around the keyboard as it moves, other than to just slide
    // things up a bit when it first appears
    
    float statusBarOffset = [view.superview convertPoint:view.frame.origin toView:self.delegate.view].y;
    
    // If not iPad return offset for scrolling view beneath the status bar.
    // If iPad shift everything down a bit from there.
    float offsetForKeyboard = statusBarOffset - ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 150.0f : 0.0f);
    
    return -offsetForKeyboard;
}

#pragma mark - Details distances

-(float)getBottomGapHeight
{
	return self.delegate.view.bounds.size.height - (self.view.frame.origin.y + self.scrollContainer.frame.size.height);;
}

-(float)tableTopVerticalDistanceFromDelegateViewBottom
{
	return self.delegate.view.bounds.size.height - self.view.frame.origin.y;
}

-(float)viewDistanceFromDelegateViewBottom:(UIView *)view
{
    // See: http://stackoverflow.com/q/6452716/135557
    float viewYinScrollView = [view.superview convertPoint:view.frame.origin toView:self.delegate.view].y;
    return self.delegate.view.frame.size.height - viewYinScrollView;
}

-(float)distanceFromDock
{
    return (self.delegate.view.frame.size.height - (DETAIL_DOCK_DISTANCE_FROM_BOTTOM / 2.0f)) - (self.view.frame.origin.y + (DETAIL_DOCK_DISTANCE_FROM_BOTTOM / 2.0f));
}

#pragma mark - Details backgrounds

-(void)configureBackgrounds
{
    // backgroundView_'s alpha gets adjusted as the slider moves.
    // It's subviews, viewAboveBackground_ and viewBelowBackground_, therefore do also.
    // Here they are created

    backgroundView_ = [[UIView alloc] initWithFrame:CGRectZero];
    viewAboveBackground_ = [[UIView alloc] initWithFrame:CGRectZero];
    viewBelowBackground_ = [[UIView alloc] initWithFrame:CGRectZero];
    NSDictionary *views = @{@"background": backgroundView_, @"above": viewAboveBackground_, @"below": viewBelowBackground_};
    
    // Add background behind slider
    backgroundView_.translatesAutoresizingMaskIntoConstraints = NO;
    backgroundView_.backgroundColor = DETAIL_VIEW_COLOR;
    backgroundView_.alpha = 0.0f;
    [self.view insertSubview:backgroundView_ belowSubview:self.scrollContainer];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[background]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[background]|" options:0 metrics:nil views:views]];

    // Add background above slider
    viewAboveBackground_.backgroundColor = DETAIL_VIEW_COLOR;
    viewAboveBackground_.translatesAutoresizingMaskIntoConstraints = NO;
    [backgroundView_ insertSubview:viewAboveBackground_ atIndex:0];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[above]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[above(==background)]" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[above][background]" options:0 metrics:nil views:views]];

    // Add background below slider
    viewBelowBackground_.backgroundColor = DETAIL_VIEW_COLOR;
    viewBelowBackground_.translatesAutoresizingMaskIntoConstraints = NO;
    [backgroundView_ insertSubview:viewBelowBackground_ atIndex:0];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[below]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[below(==background)]" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[background][below]" options:0 metrics:nil views:views]];
}

/*
-(void)retrieveFullSizedImageForRecord:(FileUpload*)record{
    // download larger image now that thumb is showing
    // need progress indicator? with "loading full sized image" messsage?
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        
        MWPromise *fetch;
        if (record.complete.boolValue) {
            CGSize screenSize = self.view.bounds.size;
            screenSize.width = screenSize.width * 3;
            screenSize.height = screenSize.height * 3;
            AspectFillThumbFetcher *aspectFillThumbFetcher = [[AspectFillThumbFetcher alloc] init];
            fetch = [aspectFillThumbFetcher fetchThumbnail:record.title size:screenSize withQueuePriority:NSOperationQueuePriorityVeryHigh];
        }
        
        [fetch done:^(id data) {
            if([data isKindOfClass:[NSMutableDictionary class]]){
                NSData *imageData = data[@"image"];
                if (imageData){
                    [imgScrollVC setImage:[UIImage imageWithData:imageData scale:1.0]];
                }
            }
        }];
        
        [fetch fail:^(NSError *error) {
        }];
    });
}

*/

@end
