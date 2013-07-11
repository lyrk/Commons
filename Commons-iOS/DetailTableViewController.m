//
//  DetailTableViewController.m
//  Commons-iOS
//
//  Created by Brion on 1/29/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "DetailTableViewController.h"
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

#define URL_IMAGE_LICENSE @"https://creativecommons.org/licenses/by-sa/3.0/"

#define DETAIL_LABEL_COLOR [UIColor whiteColor]
#define DETAIL_VIEW_COLOR [UIColor colorWithWhite:0.0f alpha:0.3f]

#define DETAIL_BORDER_COLOR [UIColor colorWithWhite:1.0f alpha:0.75f]
#define DETAIL_BORDER_WIDTH 0.0f
#define DETAIL_BORDER_RADIUS 0.0f

#define DETAIL_TABLE_CELL_BACKGROUND_COLOR [UIColor colorWithWhite:1.0f alpha:0.0f]

#define DETAIL_EDITABLE_TEXTBOX_BACKGROUND_COLOR [UIColor colorWithWhite:1.0f alpha:0.5f]
#define DETAIL_EDITABLE_TEXTBOX_TEXT_COLOR [UIColor whiteColor]
#define DETAIL_NON_EDITABLE_TEXTBOX_BACKGROUND_COLOR [UIColor colorWithWhite:1.0f alpha:0.1f]

#define DETAIL_DOCK_DISTANCE_FROM_BOTTOM ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 166.0f : 146.0f)

@interface DetailTableViewController ()

@property (weak, nonatomic) AppDelegate *appDelegate;

@end

@implementation DetailTableViewController{
    UIActivityIndicatorView *tableViewHeaderActivityIndicator_;
    UIImage *previewImage_;
    BOOL isFirstAppearance_;
    BOOL isOKtoReportDetailsScroll_;
    DescriptionParser *descriptionParser_;
    UISwipeGestureRecognizer *swipeRecognizerDown_;
    UIView *navBackgroundView_;
}

#pragma mark - Init / dealloc

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        descriptionParser_ = [[DescriptionParser alloc] init];
        isFirstAppearance_ = YES;
        isOKtoReportDetailsScroll_ = NO;
        navBackgroundView_ = nil;
    }
    return self;
}

-(void)dealloc
{
	[self.tableView removeObserver:self forKeyPath:@"contentSize"];
	[self.tableView removeObserver:self forKeyPath:@"center"];
	[self.tableView removeObserver:self forKeyPath:@"frame"];
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
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
    UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleTopMargin |
    UIViewAutoresizingFlexibleHeight |
    UIViewAutoresizingFlexibleBottomMargin;

    previewImage_ = nil;
    
    // Get the app delegate so the loading indicator may be accessed
	self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    [self.tableView registerNib:[UINib nibWithNibName:@"CategoryCell" bundle:nil] forCellReuseIdentifier:@"CategoryCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"AddCategoryCell" bundle:nil] forCellReuseIdentifier:@"AddCategoryCell"];
    
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

    
    // Load up the selected record
    FileUpload *record = self.selectedRecord;

    self.descriptionTextView.backgroundColor = DETAIL_EDITABLE_TEXTBOX_BACKGROUND_COLOR;
    self.titleTextField.backgroundColor = DETAIL_EDITABLE_TEXTBOX_BACKGROUND_COLOR;
    // Add a bit of left padding to the text box (from: http://stackoverflow.com/a/13515749/135557)
    self.titleTextField.layer.sublayerTransform = CATransform3DMakeTranslation(8, 0, 0);
    
	self.titleTextField.textColor = DETAIL_EDITABLE_TEXTBOX_TEXT_COLOR;
	self.descriptionTextView.textColor = DETAIL_EDITABLE_TEXTBOX_TEXT_COLOR;

    if (record != nil) {
        self.categoryList = [record.categoryList mutableCopy];
        self.titleTextField.text = record.title;
        self.descriptionTextView.text = record.desc;
        self.descriptionPlaceholder.hidden = (record.desc.length > 0);

        self.categoryListLabel.text = [self categoryShortList];

        // Get categories and description
        if (record.complete.boolValue) {
            self.descriptionTextView.text = [MWMessage forKey:@"details-description-loading"].text;
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self getPreviouslySavedDescriptionForRecord:record];
                [self getPreviouslySavedCategoriesForRecord:record];
            });
        }

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            if (record.complete.boolValue) {
                // Completed upload...
                self.titleTextField.enabled = NO;
                self.descriptionTextView.editable = NO;
                self.deleteButton.enabled = NO; // fixme in future, support deleting uploaded items
                self.actionButton.enabled = YES; // open link or share on the web
                self.uploadButton.enabled = NO; // fixme either hide or replace with action button?
                
                self.descriptionPlaceholder.hidden = YES;

                // Make description read-only for now
                self.descriptionTextView.userInteractionEnabled = NO;
                self.descriptionTextView.hidden = NO;
                self.descriptionLabel.hidden = NO;
                
                // fixme: load license info from wiki page
                self.licenseLabel.hidden = YES;
                self.licenseNameLabel.hidden = YES;
                self.ccByImage.hidden = YES;
                self.ccSaImage.hidden = YES;

				self.descriptionTextView.backgroundColor = DETAIL_NON_EDITABLE_TEXTBOX_BACKGROUND_COLOR;
				self.titleTextField.backgroundColor = DETAIL_NON_EDITABLE_TEXTBOX_BACKGROUND_COLOR;

                // either use HTML http://commons.wikimedia.org/wiki/Commons:Machine-readable_data
                // or pick apart the standard templates
            } else {
                // Locally queued file...
                self.titleTextField.enabled = YES;
                self.descriptionTextView.editable = YES;
                self.deleteButton.enabled = (record.progress.floatValue == 0.0f); // don't allow delete _during_ upload
                self.actionButton.enabled = NO;
                
                self.descriptionLabel.hidden = NO;
                self.descriptionTextView.hidden = NO;
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

    // Set delegates so we know when fields change...
    self.titleTextField.delegate = self;
    self.descriptionTextView.delegate = self;
    
    // Make the title text box keyboard "Done" button dismiss the keyboard
    [self.titleTextField setReturnKeyType:UIReturnKeyDone];
    [self.titleTextField addTarget:self.descriptionTextView action:@selector(becomeFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    
    // Add a "hide keyboard" button above the keyboard (when the description box has the focus and the
    // keyboard is visible). Did this so multi-line descriptions could still be entered *and* the
    // keyboard could still be dismissed (otherwise the "return" button would have to be made into a
    // "Done" button which would mean line breaks could not be entered)
    
    // Note: Only show the "hide keyboard" button for new images as existing image descriptions are
    // read-only for now

    if ((!record.complete.boolValue) && (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)){
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
    
    // Make taps to title or description labels cause their respective text boxes to receive focus
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusOnTitleTextField)];
    [self.titleCell addGestureRecognizer:tapGesture];
    
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusOnDescriptionTextView)];
    [self.descCell addGestureRecognizer:tapGesture];
    
    // Round corners of text boxes
    [self.titleTextField.layer setCornerRadius:6.0f];
    [self.descriptionTextView.layer setCornerRadius:6.0f];
    
    self.licenseNameLabel.textColor = [UIColor whiteColor];
    
    self.descriptionLabel.textColor = DETAIL_LABEL_COLOR;
    self.titleLabel.textColor = DETAIL_LABEL_COLOR;
    self.licenseLabel.textColor = DETAIL_LABEL_COLOR;
    self.categoryLabel.textColor = DETAIL_LABEL_COLOR;

    self.tableView.delaysContentTouches = NO;
    
    // Get rid of table separator lines and border
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView.layer setShadowColor:[UIColor clearColor].CGColor];

    [self.view setMultipleTouchEnabled:NO];
    
    // Keep the table view the same size as its content
    [self.tableView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionPrior context:NULL];

    // Keep track of sliding
    [self.tableView addObserver:self forKeyPath:@"center" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionPrior context:NULL];
    
    [self.tableView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionPrior context:NULL];
    
    self.view.opaque = NO;
    self.view.backgroundColor = DETAIL_VIEW_COLOR;

    self.view.layer.cornerRadius = DETAIL_BORDER_RADIUS;
    self.view.layer.borderWidth = DETAIL_BORDER_WIDTH;
    self.view.layer.borderColor = [DETAIL_BORDER_COLOR CGColor];

    // Make the table view's background transparent
    UIView *backView = [[UIView alloc] initWithFrame:CGRectZero];
    backView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = backView;

    // Without scrollEnabled, the license and category cells ignore the first touch
    // after the self.view has been dragged
    self.tableView.scrollEnabled = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
	// Note:
	// Don't call "[super viewWillAppear:animated]" here!
	// It causes the tableView to scroll if the description box receives focus
	// when it has been moved to the lower part of the screen
	// See: http://stackoverflow.com/a/12111260/135557
	// (the scrolling is unwanted because "scrollSoView:isBelowNavBar:" is being
	// used instead - for greater control)

    self.categoryList = [self.selectedRecord.categoryList mutableCopy];
    [self.tableView reloadData];

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
    isOKtoReportDetailsScroll_ = YES;
    isFirstAppearance_ = NO;
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
    [app deleteUploadRecord:self.selectedRecord];
    [app saveData];
    self.selectedRecord = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)openLicense
{
    [CommonsApp.singleton openURLWithDefaultBrowser:[NSURL URLWithString:URL_IMAGE_LICENSE]];
}

- (IBAction)openWikiPageButtonPushed:(id)sender
{
    if (self.selectedRecord) {
        NSString *pageTitle = [@"File:" stringByAppendingString:self.selectedRecord.title];
        [CommonsApp.singleton openURLWithDefaultBrowser:[CommonsApp.singleton URLForWikiPage:pageTitle]];
    }
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
        
    // Fetch cached or internet image at standard size...
    MWPromise *fetch = [CommonsApp.singleton fetchWikiImage:record.title size:[CommonsApp.singleton getFullSizedImageSize] withQueuePriority:NSOperationQueuePriorityHigh];
    
    [fetch done:^(UIImage *image) {

        // Get the wiki url for the image
        NSString *pageTitle = [@"File:" stringByAppendingString:self.selectedRecord.title];
        NSURL *wikiUrl = [CommonsApp.singleton URLForWikiPage:pageTitle];
        
        // Present the sharing interface for the image itself and its wiki url
        self.shareActivityViewController = [[UIActivityViewController alloc]
                                            initWithActivityItems:@[image, wikiUrl]
                                            applicationActivities:nil
                                            ];
        [self presentViewController:self.shareActivityViewController animated:YES completion:^{
            [self.appDelegate.loadingIndicator hide];
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
    float delay = (self.delegate.navigationItem.prompt.length == 0) ? 0.0f : 0.1f;

    // Clear out any prompt above the nav bar as soon as disabled upload button is tapped
    [self clearNavBarPrompt];

    // If user taps disabled upload button or the nav bar this causes the details table to slide up
    // Nice prompt to remind user to enter title and description. Perform after delay if the
    // navigationItem.prompt was set to give prompt time to disappear
    [self scrollToTopBeneathNavBarAfterDelay:delay];
}

-(void)clearNavBarPrompt
{
    self.delegate.navigationItem.prompt = nil;
}

-(void)makeNavBarRunAwayFromDetails
{
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        // Hide only the license row if viewing details of already-uploaded image
        if (self.selectedRecord.complete.boolValue) {
            // Hide description row if none found
            return (self.descriptionTextView.text.length == 0) ? 1 : 2;
        }
        // Fall through to static section handling...
        return [super tableView:tableView numberOfRowsInSection:section];
    } else if (section == 1) {
        if (self.selectedRecord.complete.boolValue) {
            // If no categories show one cell so it can contain "Loading..." message, else hide the add button
            // for already uploaded images as categories are read-only for them for now
            return (self.categoryList.count == 0) ? 1 : self.categoryList.count;
        }
        // Add one cell for the add button!
        return self.categoryList.count + 1;
    
    } else {
        return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 1:
            return [MWMessage forKey:@"details-category-label"].text;
        default:
            return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        // Fall through to static section handling...
        UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
        return  cell;
    } else if (indexPath.section == 1) {
        // Categories
        UITableViewCell *cell;
        
        if (self.selectedRecord.complete.boolValue) {
            // Show "Loading..." row if no categories
            if(self.categoryList.count == 0){
                cell = [tableView dequeueReusableCellWithIdentifier:@"CategoryCell"];
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.userInteractionEnabled = NO;
                cell.textLabel.text = [MWMessage forKey:@"details-category-loading"].text;
                cell.textLabel.backgroundColor = [UIColor clearColor];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
                return cell;
            }
        }
        
        if (indexPath.row < self.categoryList.count) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"CategoryCell"];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
            // Make categories read-only for now
            if (self.selectedRecord.complete.boolValue) {
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.userInteractionEnabled = NO;
            }
            
            cell.textLabel.text = self.categoryList[indexPath.row];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"AddCategoryCell"];
            cell.textLabel.text = [MWMessage forKey:@"catadd-title"].text;
            cell.textLabel.textColor = DETAIL_LABEL_COLOR;
        }
        
        cell.textLabel.backgroundColor = [UIColor clearColor];

        return cell;
    } else {
        // no exist!
        return nil;
    }
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return NO;
}

// must overload this or the static table handling explodes in cats dynamic section
-(int)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return [super tableView:tableView indentationLevelForRowAtIndexPath:indexPath];
    }
    return 5;
}

// Make the table cell backgrounds partially transparent
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = DETAIL_TABLE_CELL_BACKGROUND_COLOR;
}

// Custom style for the "Categories" table header label. http://stackoverflow.com/a/7928944/135557
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    if (sectionTitle == nil) return nil;
    
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(20, 8, 320, 20);
    label.backgroundColor = [UIColor clearColor];
    label.textColor = DETAIL_LABEL_COLOR;
    label.shadowColor = [UIColor grayColor];
    label.shadowOffset = CGSizeMake(0.0, 0.0);
    label.font = [UIFont boldSystemFontOfSize:16];
    label.text = sectionTitle;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor clearColor];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [view addSubview:label];
    return view;
}

#pragma mark - Table view delegate

// hack to hide table cells
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.item >= 1 && self.selectedRecord && self.selectedRecord.complete.boolValue) {
        if (self.selectedRecord.complete.boolValue) {
            // Resize description cell according to the retrieved description's text height
            // From: http://stackoverflow.com/a/2487402/135557
            CGRect frame = self.descriptionTextView.frame;
            frame.size.height = self.descriptionTextView.contentSize.height;
            self.descriptionTextView.frame = frame;
            return frame.size.height + frame.origin.y + 8.0f;
        }
    }
    if (indexPath.section == 1) {
        return 44; // ????? hack
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        // Static section already handled by storyboard segues.
    } else if (indexPath.section == 1) {
        if (indexPath.row < self.categoryList.count) {
            // Segue isn't connected due to nib fun. :P
            [self performSegueWithIdentifier: @"CategoryDetailSegue" sender: self];
        } else {
            // 'Add category...' cell button
            // Segue isn't connected due to nib fun. :P
            [self performSegueWithIdentifier: @"AddCategorySegue" sender: self];
        }
    }
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1 && indexPath.row < self.categoryList.count) {
        NSString *cat = self.categoryList[indexPath.row];
        NSString *encCat = [cat stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *link = [NSString stringWithFormat:@"https://commons.m.wikimedia.org/wiki/Category:%@", encCat];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link]];
    }
}

#pragma mark - Table style

-(void)removeBorderFromTableViewCell:(UITableViewCell *) cell
{    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell setAccessoryType:UITableViewCellAccessoryNone];
    cell.backgroundView = nil;
}

#pragma mark - Focus to box when title or description label tapped
- (void)focusOnTitleTextField
{
    [self.titleTextField becomeFirstResponder];
}

- (void)focusOnDescriptionTextView
{
    [self.descriptionTextView becomeFirstResponder];
}

#pragma mark - Repositioning for keyboard appearance

- (void)hideKeyboardAccessoryViewTapped
{
    [self hideKeyboard];
    // When the description field is being edited and the "hide keyboard" button is pressed
    // the nav bar needs to be revealed so the "upload" button is visible
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self scrollToTopBeneathNavBarAfterDelay:0.0f];
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
    [self scrollViewBeneathStatusBar:self.titleLabel];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    // When the description box receives focus scroll it to the top of the table view to ensure the keyboard
    // isn't hiding it
    [self scrollViewBeneathStatusBar:self.descriptionLabel];
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
            view.category = self.categoryList[self.tableView.indexPathForSelectedRow.row];
        }
    }
    
}

#pragma mark - Description and Category retrieval

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
        self.selectedRecord.categories = [self.categoryList componentsJoinedByString:@"|"];
        self.categoryListLabel.text = [self categoryShortList];
        [self.tableView reloadData];
    }];
}

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
    __weak UITableView *weakTableView = self.tableView;
    
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
                    [weakTableView reloadData];
                    
                };
                [descriptionParser_ parse];
            }
        }
    }];
    
    [req always:^(NSDictionary *result) {
        if ([weakDescriptionTextView.text isEqualToString: [MWMessage forKey:@"details-description-loading"].text]){
            weakDescriptionTextView.text = [MWMessage forKey:@"details-description-none-found"].text;
        }
    }];
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

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // Keep the table view the same size as its content
    if ([keyPath isEqualToString:@"contentSize"]) {
        NSValue *new = [change valueForKey:@"new"];
        NSValue *old = [change valueForKey:@"old"];
        if (new && old) {
            if (![old isEqualToValue:new]) {
				[self sizeTableViewToItsContents];
            }
        }
    }else if ([keyPath isEqualToString:@"center"] || [keyPath isEqualToString:@"frame"]) {
		// Keep track of sliding
        NSValue *new = [change valueForKey:@"new"];
        NSValue *old = [change valueForKey:@"old"];
        if (new && old) {
            if (![old isEqualToValue:new]) {
				//CGPoint oldCenter = old.CGPointValue;
				//CGPoint newCenter = new.CGPointValue;
				if (isOKtoReportDetailsScroll_) {
					[self reportDetailsScroll];
				}
            }
        }
    }
}

#pragma mark - Rotation

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    isOKtoReportDetailsScroll_ = NO;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // If the keyboard was visible during rotation, scroll so the field being edited is near the top of the screen
    if (self.titleTextField.isFirstResponder) {
        [self scrollViewBeneathStatusBar:self.titleLabel];
    }else if (self.descriptionTextView.isFirstResponder) {
        [self scrollViewBeneathStatusBar:self.descriptionLabel];
    }
	
	[self sizeTableViewToItsContents];
    
    isOKtoReportDetailsScroll_ = YES;
}

#pragma mark - Details moving

-(void)moveDetailsToDock
{
    CGRect f = self.view.frame;
    f.origin.y = self.delegate.view.frame.size.height - DETAIL_DOCK_DISTANCE_FROM_BOTTOM;
    self.view.frame = f;
}

-(void)moveDetailsToBottom
{
    CGRect f = self.view.frame;
    f.origin.y = self.delegate.view.frame.size.height;
    self.view.frame = f;
}

-(void)moveDetailsBeneathNav
{
    CGRect f = self.view.frame;
    f.origin.y = self.navigationController.navigationBar.frame.size.height;
    self.view.frame = f;
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
                             CGRect f = self.view.frame;
                             f.origin.y += amount;
                             self.view.frame = f;
                         }
					 }
                     completion:^(BOOL finished){
						 //self.view.layer.shouldRasterize = NO;

						 if(block != nil) block();
                     }];
}

-(void)scrollToTopBeneathNavBarAfterDelay:(float)delay
{
    [self scrollByAmount:-[self verticalDistanceFromNavBar] withDuration:0.25f delay:delay options:UIViewAnimationTransitionNone useXF:NO then:nil];
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
    CGSize rootViewSize = [UIApplication sharedApplication].keyWindow.rootViewController.view.frame.size;
    float height = (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) ? rootViewSize.height : rootViewSize.width;
    //NSLog(@"height = %f, height = %f", height, self.delegate.view.frame.size.height);
    
    float scrollValue = self.view.frame.origin.y / (height - DETAIL_DOCK_DISTANCE_FROM_BOTTOM);

    [self makeNavBarRunAwayFromDetails];

	float minChangeToReport = 0.025f;
    if (fabsf((scrollValue - lastScrollValue)) > minChangeToReport) {
        scrollValue = MIN(scrollValue, 1.0f);
        scrollValue = MAX(scrollValue, 0.0f);
        lastScrollValue = scrollValue;
		self.detailsScrollNormal = scrollValue;
		[self.delegate setDetailsScrollNormal:scrollValue];

        // Clear out any prompt above the nav bar as soon as details scrolled
        [self clearNavBarPrompt];
    }
}

-(void)scrollViewBeneathStatusBar:(UIView *)view
{
    float offset = [view.superview convertPoint:view.frame.origin toView:self.delegate.view].y;
    [self scrollByAmount:-offset withDuration:0.5f delay:0.0f options:UIViewAnimationCurveEaseOut useXF:NO then:nil];
}

#pragma mark - Details sizing

-(void)sizeTableViewToItsContents
{
	CGRect f = self.tableView.frame;
	f.size = self.tableView.contentSize;

    // Make the details table extent about a third of the screen height past the bottom
    // of the details table content. The size must be grabbed from the delegate because
    // the details view itself isn't fullscreen, so the size of the screen can't be
    // obtained from it.
    f.size.height += (self.delegate.view.bounds.size.height / 3.0f);
        
	self.tableView.frame = f;
    
    if (self.view.alpha != 0.0f) {
        // Don't mess with scrolling if the view is hidden!
        [self ensureScrollingDoesNotExceedThreshold];
    }
}

#pragma mark - Details distances

-(float)getBottomGapHeight
{
	return self.delegate.view.bounds.size.height - (self.view.frame.origin.y + self.view.frame.size.height);
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
