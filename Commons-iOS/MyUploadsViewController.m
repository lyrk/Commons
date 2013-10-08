//
//  MyUploadsViewController.m
//  Commons-iOS
//
//  Created by Brion on 2/5/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MyUploadsViewController.h"
#import "CommonsApp.h"
#import "ImageListCell.h"
#import "DetailScrollViewController.h"
#import "MWI18N/MWI18N.h"
#import "Reachability.h"
#import "SettingsViewController.h"
#import "WelcomeOverlayView.h"
#import "FetchImageOperation.h"
#import "ProgressView.h"
#import "LoginViewController.h"
#import "GalleryMultiSelectCollectionVC.h"
#import "ImageScrollViewController.h"
#import "AspectFillThumbFetcher.h"
//#import "UIView+Debugging.h"

#define OPAQUE_VIEW_ALPHA 0.7
#define OPAQUE_VIEW_BACKGROUND_COLOR blackColor
#define BUTTON_ANIMATION_DURATION 0.25

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface MyUploadsViewController () {
    NSString *pickerSource_;
    UITapGestureRecognizer *tapRecognizer_;
    bool buttonAnimationInProgress_;
    UIView *opaqueView_;
    NSUInteger thumbnailCount_;
    
    ImageScrollViewController *imageScrollVC_;
    DetailScrollViewController *detailVC_;
    UITapGestureRecognizer *imageTapRecognizer_;
    UITapGestureRecognizer *imageDoubleTapRecognizer_;
    UITapGestureRecognizer *imageTwoFingerTapRecognizer_;
}

@end

@implementation MyUploadsViewController

#pragma mark - Init

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        thumbnailCount_ = 0;
        self.wantsFullScreenLayout = YES;
    }
    return self;
}

#pragma mark - View lifecycle

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Set up refresh
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshButtonPushed:)
                  forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.refreshControl];
    self.refreshControl.hidden = YES;

    if (thumbnailCount_ != 0){
        // Ensure welcome message is hidden if the user has images
        [self.welcomeOverlayView showMessage:WELCOME_MESSAGE_NONE];
    }else{
        // Else show the message if a refresh is not in progress
        if (!self.refreshControl.isRefreshing){
            [self.welcomeOverlayView showMessage:WELCOME_MESSAGE_WELCOME];
        }else{
            [self.welcomeOverlayView showMessage:WELCOME_MESSAGE_CHECKING];
        }
    }
    
    // Observe changes to the number of items in the fetch queue
    // (only observe operationCount while this view controller's view is onscreen - remove
    // self as observer in viewWillDisappear)
    CommonsApp *app = [CommonsApp singleton];
    [app.fetchDataURLQueue addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
    
    // Remove the record if needed. Moved deletions here so they can happen after the
    // My Uploads is revealed when popping Details after delete tapped. Otherwise
    // collection view had an autolayout fit.
    if (app.recordToDelete != nil) {
        [app deleteUploadRecord:self.selectedRecord];
        app.recordToDelete = nil;
    }
    
    // Enables jumping straight to Settings page for quick debugging
    //SettingsViewController *settingsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingsViewController"];
    //[self.navigationController pushViewController:settingsVC animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Shift the messageLabel down a bit on iPads
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        self.welcomeOverlayView.messageLabel.frame = CGRectOffset(self.welcomeOverlayView.messageLabel.frame, 0.0, 240.0);
    }
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChange:) name:kReachabilityChangedNotification object:nil];

    self.title = [MWMessage forKey:@"contribs-title"].text;
    self.uploadButton.title = [MWMessage forKey:@"contribs-upload-button"].text;
    //self.choosePhotoButton.title = [MWMessage forKey:@"contribs-photo-library-button"].text; // fixme set accessibility title
    
    if ([self hasCamera]) {
        // Camera is available
    } else {
        // Clicking 'take photo' in simulator *will* crash, so disable the button.
        self.takePhotoButton.enabled = NO;
    }
    self.takePhotoButton.hidden = YES;
    self.choosePhotoButton.hidden = YES;
    
    CommonsApp *app = [CommonsApp singleton];
    [app fetchUploadRecords];
    app.fetchedResultsController.delegate = self;
    
    if (app.username == nil || [app.username isEqualToString:@""]) {
        [self performSegueWithIdentifier:@"SettingsSegue" sender:self];
    }
    
    // Hide take and choose photo buttons when anywhere else is tapped
	tapRecognizer_ = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideTakeAndChoosePhotoButtons:)];
    
    // By not cancelling touches in view the tapping the images in the background will cause the tapped image details view to load
    [tapRecognizer_ setCancelsTouchesInView:NO];
    
    // Makes "gestureRecognizer:shouldReceiveTouch:" be called so decisions may be made about which interface elements respond to tapRecognizer touches
    [tapRecognizer_ setDelegate:self];
    
	[self.view addGestureRecognizer:tapRecognizer_];
    
    buttonAnimationInProgress_ = NO;

    // Opaque view is used to fade out background when take and choose photo buttons are revealed
    [self setupOpaqueView];
    
    // Make the About and Settings buttons stand out better against light colors
    [LoginViewController applyShadowToView:self.settingsButton];
    [LoginViewController applyShadowToView:self.aboutButton];

    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        // For iOS 7 turn auto scroll view insets off since we manually add them for ios 6 compatibility
        // (the inset is added with "setCollectionViewTopInset")
        self.automaticallyAdjustsScrollViewInsets = NO;
    }

    // Change back button to be an arrow
    self.navigationItem.leftBarButtonItem = [[CommonsApp singleton] getBackButtonItemWithTarget:self action:@selector(backButtonPressed:)];
    
    //[self.view randomlyColorSubviews];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
  
    // When the debug mode is toggled the fetchedResultsController.delegate was getting blasted for some reason
    // This resets it
    [CommonsApp singleton].fetchedResultsController.delegate = self;
    
    self.uploadButton.enabled = [[CommonsApp singleton] firstUploadRecord] ? YES : NO;
    
    // hide the standard toolbar?
    [self.navigationController setToolbarHidden:YES animated:YES];

	// Reveal the nav bar now that the login page is no longer showing (it's supressed on the login page)
	[self.navigationController setNavigationBarHidden:NO animated:animated];

    // Update collectionview cell size for iPhone/iPod, in case orientation changed while we were away
    [self.collectionView.collectionViewLayout invalidateLayout];
    
    // Ensure the iPad image picker will appear (without this if a picture is picked, then you back up and
    // to pick another one it won't let you)
    self.popover = nil;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // No longer observe changes to the number of items in the fetch queue
    // (only observe operationCount while this view controller's view is onscreen)
    CommonsApp *app = [CommonsApp singleton];
    
    // Approach recommended by: http://stackoverflow.com/a/6714561/135557
    @try{
        [app.fetchDataURLQueue removeObserver:self forKeyPath:@"operationCount"];
    }@catch(id anException){
        NSLog(@"THE OBSERVER WASN'T REGISTERED!");
    }
    
    // Prevent the overlay message from flickering as the view disappears
    [self.welcomeOverlayView showMessage:WELCOME_MESSAGE_NONE];
}


#pragma mark - Camera

-(BOOL)hasCamera
{
    return [UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera];
}

#pragma mark - Reachability

-(void)reachabilityChange:(NSNotification*)note {
    Reachability * reach = [note object];
    NetworkStatus netStatus = [reach currentReachabilityStatus];
    if (netStatus == ReachableViaWiFi || netStatus == ReachableViaWWAN)
    {
        self.uploadButton.enabled = [[CommonsApp singleton] firstUploadRecord] ? YES : NO;;
    }
    else if (netStatus == NotReachable)
    {
        self.uploadButton.enabled = NO;
    }
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Opaque view

-(void)setupOpaqueView
{
    opaqueView_ = [[UIView alloc] init];
    opaqueView_.translatesAutoresizingMaskIntoConstraints = NO;
    opaqueView_.hidden = YES;
    opaqueView_.backgroundColor = [UIColor clearColor];
    [self.view addSubview:opaqueView_];

    // Constrain the opaque view to take up the whole screen
    void (^constrain)(NSString *) = ^(NSString * str){
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:str
                                                                          options:0
                                                                          metrics:0
                                                                            views:NSDictionaryOfVariableBindings(opaqueView_)]];
    };
    constrain(@"H:|[opaqueView_]|");
    constrain(@"V:|[opaqueView_]|");
}

#pragma mark - Layout

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    [self setCollectionViewTopInset];

    // UIViews don't have access to self.interfaceOrientation, this gets around that so the
    // welcomeOverlayView can adjust its custom drawing when it needs to
    self.welcomeOverlayView.interfaceOrientation = self.interfaceOrientation;
}

-(void)setCollectionViewTopInset
{
    // Keep the top of the collectionView just below the bottom of the nav bar
    self.spaceAboveCollectionViewConstraint.constant = self.navigationController.navigationBar.frame.size.height + [[CommonsApp singleton] getStatusBarHeight];
}

#pragma mark - Thumb Download Prioritization

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // Don't take action on observations if the view controller's view is no longer visible
    if (self.navigationController.topViewController != self) return;
    
    // When the number of operations in fetchDataURLQueue changes make the download operations
    // for images of on-screen cells jump to front of the queue - makes interface seem MUCH
    // snappier
    CommonsApp *app = [CommonsApp singleton];
    if (object == app.fetchDataURLQueue && [keyPath isEqualToString:@"operationCount"]) {
        [self raiseDowloadPriorityForImagesOfOnscreenCells];
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)raiseDowloadPriorityForImagesOfOnscreenCells
{
    CommonsApp *app = [CommonsApp singleton];
    if (app.fetchDataURLQueue.operationCount > 0) {
        for (FetchImageOperation *op in app.fetchDataURLQueue.operations) {
            
            // If the op is already running (or is finished) ignore it as adjusting the
            // priority at that point wouldn't really matter
            if (op.isExecuting || op.isCancelled || op.isFinished) continue;
            
            if ([self isOpCellOnScreen:op]){
                NSLog(@"SET HIGH FOR %@", op.url);
                [op setQueuePriority:NSOperationQueuePriorityHigh];
            }else{
                [op setQueuePriority:NSOperationQueuePriorityNormal];
            }
        }
    }
}

- (BOOL)isOpCellOnScreen:(FetchImageOperation *)op
{
    // Should find better way to determine a cell's file - below it's using the title from the FileUpload record
    
    // The title has had its underscores replaces with spaces, so to match the title to the url
    // the url must do the same
    NSString *urlNoUnderscore = [[op.url path] stringByReplacingOccurrencesOfString:@"_" withString:@" "];

    CommonsApp *app = CommonsApp.singleton;
    for (NSIndexPath *indexPath in [self.collectionView indexPathsForVisibleItems]) {
        FileUpload *record = (FileUpload *)[app.fetchedResultsController objectAtIndexPath:indexPath];
        
        if ([urlNoUnderscore hasSuffix:record.title]) return YES;
    }
    return NO;
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
    [CommonsApp.singleton prepareImage:info from:pickerSource_];
    [self dismissViewControllerAnimated:YES completion:nil];
    if (self.popover) {
        [self.popover dismissPopoverAnimated:YES];
    }
    self.choosePhotoButton.hidden = YES;
    self.takePhotoButton.hidden = YES;
    
    self.uploadButton.enabled = YES;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSLog(@"canceled");
    [self dismissViewControllerAnimated:YES completion:nil];
    self.choosePhotoButton.hidden = YES;
    self.takePhotoButton.hidden = YES;
}

#pragma mark - Interface Items

- (UIBarButtonItem *)uploadButton {
    
    if (!_uploadButton) {
        
        _uploadButton = [[UIBarButtonItem alloc] initWithTitle:[MWMessage forKey:@"details-upload-button"].text
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(uploadButtonPushed:)];
    }

    [_uploadButton setTitleTextAttributes:@{
                                            UITextAttributeFont: [UIFont boldSystemFontOfSize:16]
                                            } forState:UIControlStateNormal];

    [_uploadButton setBackgroundImage:[UIImage imageNamed:@"clear.png"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    return _uploadButton;
}

- (UIBarButtonItem *)cancelButton {
    
    UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(cancelButtonPushed:)];

    [btn setTitleTextAttributes:@{
                                  UITextAttributeFont: [UIFont boldSystemFontOfSize:16]
                                  } forState:UIControlStateNormal];

    [btn setBackgroundImage:[UIImage imageNamed:@"clear.png"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];

    return btn;
}

#pragma mark - Interface Actions

-(void)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)uploadButtonPushed:(id)sender {
    
    // Pop to this view controller (in case upload button was pressed from the details page)
    [self.navigationController popToViewController:self animated:YES];
    
    CommonsApp *app = [CommonsApp singleton];
    
    // Only allow uploads if user is logged in
    if (![app.username isEqualToString:@""] && ![app.password isEqualToString:@""]) {
        // User is logged in
        
        if ([app.fetchedResultsController.fetchedObjects count] > 0) {
            
            // Scroll to top so the thumb for the file being uploaded can be seen - as can its upload
            // progress indicator
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];

            [self.navigationItem setRightBarButtonItem:[self cancelButton] animated:YES];
            
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
                        
                        self.navigationItem.rightBarButtonItem = [self uploadButton];
                        
                        NSString *alertTitle = ([error.domain isEqualToString:@"MediaWiki API"] && (error.code == MW_ERROR_UPLOAD_CANCEL))
                        ?
                        [MWMessage forKey:@"error-upload-cancelled"].text
                        :
                        [MWMessage forKey:@"error-upload-failed"].text
                        ;
                        
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle
                                                                            message:[MWApi getMessageForError:error]
                                                                           delegate:nil
                                                                  cancelButtonTitle:[MWMessage forKey:@"error-dismiss"].text
                                                                  otherButtonTitles:nil];
                        [alertView show];
                        
                        run = nil;
                    }];
                } else {
                    NSLog(@"no more uploads");
                    [self.navigationItem setRightBarButtonItem:self.uploadButton animated:YES];
                    [self.navigationItem.rightBarButtonItem setEnabled:NO];
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
    
    [self hideTakeAndChoosePhotoButtons:nil];
    
    NSLog(@"Take photo");
    pickerSource_ = @"camera";
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
    
    [self hideTakeAndChoosePhotoButtons:nil];
    
    NSLog(@"Open gallery");
    pickerSource_ = @"gallery";
    
    [self presentGalleryPicker];
}

-(void)presentGalleryPicker
{
    //[self presentSingleImageGalleryPicker];
    [self presentMultiImageGalleryPicker];
}

-(void)presentMultiImageGalleryPicker
{
    GalleryMultiSelectCollectionVC *galleryMultiSelectCollectionVC = [self.storyboard instantiateViewControllerWithIdentifier:@"GalleryMultiSelectCollectionVC"];
    
    galleryMultiSelectCollectionVC.didFinishPickingMediaWithInfo = ^(NSDictionary *info){
        NSLog(@"picked: %@", info);
        MWPromise *done = [CommonsApp.singleton prepareImage:info from:pickerSource_];
        //[done always:^(id arg) {
            [self dismissViewControllerAnimated:NO completion:nil];
            if (self.popover) {
                [self.popover dismissPopoverAnimated:NO];
            }
            self.choosePhotoButton.hidden = YES;
            self.takePhotoButton.hidden = YES;
            self.uploadButton.enabled = YES;
        //}];
    };
    
    [self presentViewController:galleryMultiSelectCollectionVC animated:YES completion:^{}];    
}

-(void)presentSingleImageGalleryPicker
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (!self.popover) { // prevent crash when choose photo is tapped twice in succession
            self.popover = [[UIPopoverController alloc] initWithContentViewController:picker];
            self.popover.delegate = self;
            CGRect rect = self.choosePhotoButton.frame;
            [self.popover presentPopoverFromRect:rect
                                          inView:self.view
                        permittedArrowDirections:UIPopoverArrowDirectionAny
                                        animated:YES];
        }
    } else {
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (void)refreshImages {
    // Cause the images to be refreshed and the refresh control title to be updated to
    // say "Refreshing..." during said refreshiness
    
    MWPromise *refresh = [CommonsApp.singleton refreshHistoryWithFailureAlert:YES];
    
    [refresh always:^(id arg) {
        [self.refreshControl endRefreshing];
        
        // Now that the refresh is done it is known whether there are images, so show the welcome message if needed
        if (thumbnailCount_ == 0) {
            if (self.takePhotoButton.hidden) {
                [self.welcomeOverlayView showMessage:WELCOME_MESSAGE_WELCOME];
            }else{
                [self.welcomeOverlayView showMessage:WELCOME_MESSAGE_CHOOSE_OR_TAKE];
            }
        }else{
            [self.welcomeOverlayView showMessage:WELCOME_MESSAGE_NONE];
        }
        
    }];
}

- (IBAction)refreshButtonPushed:(id)sender {
    [self refreshImages];
}

- (IBAction)settingsButtonPushed:(id)sender {
	
	NSLog(@"Settings Button Pushed");

    [CATransaction begin];
    [CATransaction setAnimationDuration:0.2f];
    // Spin and enlarge the settings button briefly up tapping it
    CABasicAnimation *spinAndEnlargeAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    spinAndEnlargeAnimation.fillMode = kCAFillModeForwards;
    spinAndEnlargeAnimation.autoreverses = YES;
    spinAndEnlargeAnimation.removedOnCompletion = YES;
    CATransform3D xf = CATransform3DConcat(CATransform3DMakeRotation(DEGREES_TO_RADIANS(180.0f), 0.0f, 0.0f, 1.0f),
                                           CATransform3DMakeScale(1.8f, 1.8f, 1.0f));
    spinAndEnlargeAnimation.toValue = [NSValue valueWithCATransform3D:xf];
    [CATransaction setCompletionBlock:^{
        // Push the settings view controller on to the nav controller now that the little animation is done
        SettingsViewController *settingsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingsViewController"];
        [self.navigationController pushViewController:settingsVC animated:YES];
    }];
    [self.settingsButton.layer addAnimation:spinAndEnlargeAnimation forKey:nil];
    [CATransaction commit];
}

- (IBAction)addMediaButtonPushed:(id)sender {
    
    // Ensure the toggle can't be toggled again until any animation from a previous toggle has completed
    if (buttonAnimationInProgress_) return;
    
    [self animateTakeAndChoosePhotoButtons];

    // Ensure the welcome overlay remains above the opaqueView
    [self.view bringSubviewToFront:self.welcomeOverlayView];
}

- (void)cancelButtonPushed:(id)sender {
    
    CommonsApp *app = [CommonsApp singleton];
    [app cancelCurrentUpload];
    
    [self.navigationItem setRightBarButtonItem:self.uploadButton animated:YES];
    self.uploadButton.enabled = [[CommonsApp singleton] firstUploadRecord] ? YES : NO;
}

- (void)animateTakeAndChoosePhotoButtons {
    
    CABasicAnimation *(^xfAnimation)(CATransform3D, float, float) = ^(CATransform3D xf, float delay, float duration){
        CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"transform"];
        a.fillMode = kCAFillModeForwards;
        a.autoreverses = NO;
        a.duration = duration;
        a.removedOnCompletion = NO;
        [a setBeginTime:CACurrentMediaTime() + delay];
        a.toValue = [NSValue valueWithCATransform3D:xf];
        return a;
    };
    
    // Animates the take and choose photo buttons from their storyboard location to the location of the add media button
    // and vice-versa.
    
    // Remember the pre-animation location so the buttons may be returned to them
    CGPoint takePhotoButtonOriginalCenter;
    CGPoint choosePhotoButtonOriginalCenter;
    
    // Disable all button user interaction during the animation so quick repeated taps don't accidentally result in
    // unwanted action
    self.takePhotoButton.enabled = NO;
    self.choosePhotoButton.enabled = NO;
    
    // Use the visibility of the take photo button as a flag to know whether to hide or show
    if (self.takePhotoButton.hidden) {
        [self.view bringSubviewToFront:opaqueView_];
        [self.view bringSubviewToFront:self.takePhotoButton];
        [self.view bringSubviewToFront:self.choosePhotoButton];
        [self.view bringSubviewToFront:self.addMediaButton];
        
        // Run the "show buttons" animation (first move the take and choose buttons to the add media button position)
        takePhotoButtonOriginalCenter = self.takePhotoButton.center;
        choosePhotoButtonOriginalCenter = self.choosePhotoButton.center;
        self.takePhotoButton.center = self.addMediaButton.center;
        self.choosePhotoButton.center = self.addMediaButton.center;
        
        // Make the take and choose buttons twist as they're revealed and hidden.
        [self.takePhotoButton.layer addAnimation:
         xfAnimation(CATransform3DMakeRotation(DEGREES_TO_RADIANS(-90), 0, 0, 1), 0.0f, 0.0f)
                                          forKey:nil];

        [self.choosePhotoButton.layer addAnimation:
         xfAnimation(CATransform3DMakeRotation(DEGREES_TO_RADIANS(90), 0, 0, 1), 0.0f, 0.0f)
                                            forKey:nil];

        opaqueView_.hidden = NO;
        [UIView animateWithDuration:BUTTON_ANIMATION_DURATION
                              delay:0.0
                            options:UIViewAnimationOptionTransitionNone
                         animations:^{
                             // Animate the take and choose buttons to their original storyboard positions
                             self.takePhotoButton.center = takePhotoButtonOriginalCenter;
                             self.choosePhotoButton.center = choosePhotoButtonOriginalCenter;
                             self.takePhotoButton.hidden = NO;
                             self.choosePhotoButton.hidden = NO;
                             buttonAnimationInProgress_ = YES;

                             self.addMediaButton.alpha = 0.25;
                             
                             // Also animate the opaque view from transparent to partially opaque
                             [opaqueView_ setAlpha:OPAQUE_VIEW_ALPHA];
                             opaqueView_.backgroundColor = [UIColor OPAQUE_VIEW_BACKGROUND_COLOR];
                             
                         }
                         completion:^(BOOL finished){
                             self.takePhotoButton.enabled = [self hasCamera];
                             self.choosePhotoButton.enabled = YES;
                             buttonAnimationInProgress_ = NO;
                             
                             // Now that the addMediaButton was tapped, change the welcome message to
                             // describe the take and choose photo buttons. Only do so if the user has
                             // no images
                             if(thumbnailCount_ == 0){
                                 [self.welcomeOverlayView showMessage:WELCOME_MESSAGE_CHOOSE_OR_TAKE];
                             }
                         }];
        
        // Shrink the add media button when it's tapped
        [self.addMediaButton.layer addAnimation:
            xfAnimation(CATransform3DMakeScale(0.65f, 0.65f, 1.0f), 0.0f, BUTTON_ANIMATION_DURATION)
                                         forKey:nil];
        
        // Reveal the choose button
        [self.choosePhotoButton.layer addAnimation:
            xfAnimation(CATransform3DIdentity, 0.0f, BUTTON_ANIMATION_DURATION)
                                            forKey:nil];
        
        // Reveal the take button
        [self.takePhotoButton.layer addAnimation:
            xfAnimation(CATransform3DIdentity, 0.0f, BUTTON_ANIMATION_DURATION)
                                          forKey:nil];
    }else{
        
        // Assuming a user with no images may need a little prompting, show a welcome message
        if(thumbnailCount_ == 0) [self.welcomeOverlayView showMessage:WELCOME_MESSAGE_WELCOME];
        
        // Run the "hide buttons" animation, essentially unwinding the animations above
        takePhotoButtonOriginalCenter = self.takePhotoButton.center;
        choosePhotoButtonOriginalCenter = self.choosePhotoButton.center;
        [UIView animateWithDuration:BUTTON_ANIMATION_DURATION
                              delay:0.0
                            options:UIViewAnimationOptionTransitionNone
                         animations:^{
                             self.takePhotoButton.center = self.addMediaButton.center;
                             self.choosePhotoButton.center = self.addMediaButton.center;
                             buttonAnimationInProgress_ = YES;
                             
                             self.addMediaButton.alpha = 1.0;
                             
                             [opaqueView_ setAlpha:1.0];
                             opaqueView_.backgroundColor = [UIColor clearColor];
                         }
                         completion:^(BOOL finished){
                             self.takePhotoButton.hidden = YES;
                             self.choosePhotoButton.hidden = YES;
                             self.takePhotoButton.center = takePhotoButtonOriginalCenter;
                             self.choosePhotoButton.center = choosePhotoButtonOriginalCenter;
                             buttonAnimationInProgress_ = NO;
                             opaqueView_.hidden = YES;
                         }];

        // Make the add media button swell as the take and choose buttons are hidden.
        // Almost makes it appear to swallow them.
        [self.addMediaButton.layer addAnimation:
            xfAnimation(CATransform3DMakeScale(1.25f, 1.25f, 1.0f), 0.0f, BUTTON_ANIMATION_DURATION)
                                         forKey:nil];

        [self.addMediaButton.layer addAnimation:
            xfAnimation(CATransform3DIdentity, BUTTON_ANIMATION_DURATION, 0.0f)
                                         forKey:nil];

        // Rotate the choose and take photo buttons slightly as they are hidden
        [self.choosePhotoButton.layer addAnimation:
            xfAnimation(CATransform3DMakeRotation(DEGREES_TO_RADIANS(90), 0, 0, 1), 0.0f, BUTTON_ANIMATION_DURATION)
                                            forKey:nil];

        [self.takePhotoButton.layer addAnimation:
            xfAnimation(CATransform3DMakeRotation(DEGREES_TO_RADIANS(-90), 0, 0, 1), 0.0f, BUTTON_ANIMATION_DURATION)
                                          forKey:nil];
    }
}

-(void)hideTakeAndChoosePhotoButtons:(UIGestureRecognizer *)gestureRecognizer {
    // Calls "animateTakeAndChoosePhotoButtons" to animate the hiding of the buttons
    if (!self.takePhotoButton.hidden) [self animateTakeAndChoosePhotoButtons];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    // The tapRecognizer is used to hide the take and choose photo buttons (via hideTakeAndChoosePhotoButtons)
    // but it should not hide the buttons if the buttons are already being hidden (if buttonAnimationInProgress is YES)
    // It should also ignore taps on the add media and take and choose photo buttons
    if (gestureRecognizer == tapRecognizer_) {
        
        if (buttonAnimationInProgress_) return NO;
        if (touch.view == self.addMediaButton) return NO;
        if (touch.view == self.takePhotoButton) return NO;
        if (touch.view == self.choosePhotoButton) return NO;
    }
    
	if (
        (gestureRecognizer == imageTapRecognizer_)
        ||
        (gestureRecognizer == imageDoubleTapRecognizer_)
        ||
        (gestureRecognizer == imageTwoFingerTapRecognizer_)
    ) {
		// Ignore touches which fall on the details table or its contents
		if (!(
            imageScrollVC_.imageScrollView == touch.view
            ||
            imageScrollVC_.imageView == touch.view
        )) return NO;
	}
	
    return YES;
}

-(BOOL)shouldAutorotate
{
    // Don't auto rotate if animateTakeAndChoosePhotoButtons is currently moving the buttons
    // This is needed because the button animation code relies on the storyboard button locations
    // and these button locations are changed by when the device rotates
    return (!buttonAnimationInProgress_);
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
        {
            [self.collectionView insertItemsAtIndexPaths:@[newIndexPath]];
            FileUpload *record = (FileUpload *)anObject;
            if (!record.complete.boolValue) {
                // This will go crazy if we import multiple items at once :)
                self.selectedRecord = record;
                // A new picture was taken or selected
                [self pushDetailsForImageForRecord:self.selectedRecord];
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
    self.choosePhotoButton.hidden = YES;
    self.takePhotoButton.hidden = YES;
}


#pragma mark - UICollectionViewDelegate methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // CollectionView image was tapped, so show its details
    [self pushDetailsForImageForRecord:self.selectedRecord];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.refreshControl.hidden = NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CommonsApp *app = [CommonsApp singleton];
    FileUpload *record = (FileUpload *)[app.fetchedResultsController objectAtIndexPath:indexPath];
    self.selectedRecord = record;
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //self.selectedRecord = nil; //  hmmmm
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout  *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // iPad: fit 3 across in portrait or 4 across landscape
        if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
            return CGSizeMake(256.0f - 3.0f, 240.0f);
        } else {
            return CGSizeMake(256.0f - 3.5f, 240.0f);
        }
    } else {
        // iPhone/iPod: fit 1 across in portrait, 2 across in landscape
        CGSize screenSize = UIScreen.mainScreen.bounds.size;
        if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
            return CGSizeMake(screenSize.width, 240.0f);
        } else {
            return CGSizeMake(screenSize.height / 2.0f - 2.5f, 240.0f);
        }
    }
}

#pragma mark - UICollectionViewDataSource methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    CommonsApp *app = [CommonsApp singleton];
    NSUInteger count = 0;
    
    if (app.fetchedResultsController != nil) {
        NSLog(@"rows: %d objects", app.fetchedResultsController.fetchedObjects.count);
       
        // If you delete the app and reinstall it, your username/password may remain on the keychain.
        // Result is that we bypass login screen but don't trigger a refresh -- and we see zero items.
        // Refreshes here if zero items.
        if (app.fetchedResultsController.fetchedObjects.count == 0) {
            // Force the refresh spinner to start
            [self.refreshControl beginRefreshing];

            [self refreshImages];
        }
        count = app.fetchedResultsController.fetchedObjects.count;
    } else {
        count = 0;
    }
    
    thumbnailCount_ = count;

    return count;
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
    FileUpload *record = (FileUpload *)[app.fetchedResultsController objectAtIndexPath:indexPath];

    [cell constrainSubviews];
    
    //NSString *indexPosition = [NSString stringWithFormat:@"%d", indexPath.item + 1];
    //cell.indexLabel.text = indexPosition;
    // fixme indexPosition doesn't always update when we add new items

    NSString *title = record.title;
    NSString *noExtFileName = [[record.title lastPathComponent] stringByDeletingPathExtension];
    
    // Title for queued images which have no title yet
    if (noExtFileName.length == 0) noExtFileName = [MWMessage forKey:@"contribs-untitled"].text;
    
    NSString *labelText = @"";
    cell.titleLabel.text = @"";

    //cell.infoBox.backgroundColor = [UIColor clearColor];

    float progress = 0.0f;
    
    if (record.complete.boolValue) {
        // Old upload, already complete.
        if ((record.fetchThumbnailProgress.floatValue > 0.0f) && (record.fetchThumbnailProgress.floatValue != 1.0f)) {
            // Reset the download progress bar (the cell.infoBox) to reflect any previous progress
            progress = record.fetchThumbnailProgress.floatValue;
            // Make thumbnail title say "Downloading *filename*"
            labelText = [MWMessage forKey:@"contribs-state-downloading" param:noExtFileName].text;
        }else{
            labelText = noExtFileName;
        }
    } else {
        // Queued upload, not yet complete.
        // We have local data & progress info.
        if (record.progress.floatValue == 0.0f) {
            // Make thumbnail title say "Queued *filename*"
            labelText = [MWMessage forKey:@"contribs-state-queued" param:noExtFileName].text;
        }else if (record.progress.floatValue == 1.0f) {
            labelText = [MWMessage forKey:@"contribs-state-generating-thumb" param:noExtFileName].text;
        } else {
            // Make thumbnail title say "Uploading *filename*"
            labelText = [MWMessage forKey:@"contribs-state-uploading" param:noExtFileName].text;
        }
        progress = record.progress.floatValue;
    }

    // Set title label text and resize the label to fit no matter how much text there is
    [cell resizeTitleLabelWithTitle:labelText fileName:noExtFileName];
    //cell.titleLabel.text = labelText;

    // Do not animate this progress setting. It needs to directly jump to the proper progress
    cell.infoBox.progressNormal = progress;
    [cell.infoBox setNeedsDisplay];


    
    if (cell.title && [cell.title isEqual:title]) {
        // Image should already be loaded.
        NSLog(@"already loaded a title");
    } else {
        // Save the title for future checks...
        cell.title = title;

        //cell.image.contentMode = UIViewContentModeCenter;
        //[cell showPlaceHolderImage];
        cell.image.image = nil;
        
        // Load Image for cell.
        // If you quickly scrolled through a large image set - especially on iPad - you'd get jitter
        // mostly caused by loading image from file system blocking the main thread. So dispatch_async
        // loading of the image eliminates most of the remaining fast-scroll jitter.
        // (See: http://stackoverflow.com/a/5574667/135557 for more info)
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            MWPromise *fetchThumb = [record fetchThumbnailWithQueuePriority:NSOperationQueuePriorityNormal];
            [fetchThumb done:^(UIImage *image) {
                if ([cell.title isEqualToString:title]) {
                    // Also invoke the image setter asynchronously
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        cell.image.contentMode = UIViewContentModeScaleAspectFill;
                        cell.image.image = image;
                    });
                }
            }];
    
            [fetchThumb fail:^(NSError *error) {
                NSLog(@"failed to load thumbnail");
            }];
        
            [fetchThumb progress:^(NSDictionary *dict) {
                if ([cell.title isEqualToString:title]) {
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        
                        // Make the download progress bar (the cell.infoBox) reflect new progress
                        NSNumber *bytesReceived = dict[@"received"];
                        NSNumber *bytesTotal = dict[@"total"];
                        
                        if (bytesTotal.floatValue == 0.0f) return;
                        float progress = (bytesReceived.floatValue / bytesTotal.floatValue);
                        
                        //NSLog(@"progress = %f", progress);
                        NSString *noExtFileName = [[cell.title lastPathComponent] stringByDeletingPathExtension];
                        NSString *labelText = @"";
                        if (progress == 1.0f) {
                            // Make thumbnail title say "*filename*"
                            labelText = noExtFileName;
                            //cell.infoBox.backgroundColor = [UIColor clearColor];
                            progress = 0.0f;
                        }else{
                            // Make thumbnail title say "Downloading *filename*"
                            labelText = [MWMessage forKey:@"contribs-state-downloading" param:noExtFileName].text;
                        }
                        
                        // Set title label text and resize the label to fit no matter how much text there is
                        [cell resizeTitleLabelWithTitle:labelText fileName:noExtFileName];
                        //cell.titleLabel.text = labelText;
                        
                        // Could animate from current progressNormal to progress here. Problem with previous
                        // attempt to do so was during fast scroll having animation timer firing after cell
                        // was no longer showing the image it was when the firings were scheduled... figure
                        // out how to properly ignore such out of sync updates before animating progress here
                        cell.infoBox.progressNormal = progress;
                        [cell.infoBox setNeedsDisplay];
                    });
                }
            }];
            // Don't do a fetch thumb "always:" callback here in order to change cell.titleLabel.text
            // This is because the *upload image* code may also need to change cell.titleLabel.text
        });
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Clear out the lines as they are invalid for the new orientation
    [self.welcomeOverlayView clearLines];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // Update collectionview cell size for iPhone/iPod
    [self.collectionView.collectionViewLayout invalidateLayout];

    // Ensure cells are redrawn to account for the orientatiton change
    // Not sure why invalidateLayout doesn't completely take care of this
    //[self.collectionView reloadItemsAtIndexPaths:self.collectionView.indexPathsForVisibleItems];

    [self setCollectionViewTopInset];
    
    // Update the lines for the new orientation
    [self.welcomeOverlayView animateLines];
}

#pragma mark Open image in details

// Shows the image preview with details slider for the specified record.
- (void)pushDetailsForImageForRecord:(FileUpload *)record
{
    if (record == nil) return;
        
    imageScrollVC_ = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"ImageScrollViewController"];
    
    [self addDetailsViewToImageScrollViewController];
    
    [self addRightBarButtonsToImageScrollVC];
    
    // Allow the newly created detailsVC to access the upload button too
    detailVC_.uploadButton = self.uploadButton;

    imageScrollVC_.title = @"";  //[MWMessage forKey:@"details-title"].text; //record.title;
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
    
        MWPromise *fetch = [record fetchThumbnailWithQueuePriority:NSOperationQueuePriorityVeryHigh];
        [fetch done:^(id data) {

            // If a local file was loaded (from the "else" clause above) data will contain an image
            if([data isKindOfClass:[UIImage class]]){
                [imageScrollVC_ setImage:data];
            }else if([data isKindOfClass:[NSMutableDictionary class]]){
                // If image sized to fit within self.view was downloaded (from the "if" clause above)
                // data will contain a dict with an "image" entry
                NSData *imageData = data[@"image"];
                if (imageData){
                    UIImage *image = [UIImage imageWithData:imageData scale:1.0];
                    [imageScrollVC_ setImage:image];
                }
            }

[self.navigationController pushViewController:imageScrollVC_ animated:YES];

        }];

        [fetch fail:^(NSError *error) {
            NSLog(@"Failed to download image: %@", [error localizedDescription]);
        }];
    });
}

-(void)addRightBarButtonsToImageScrollVC
{
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                 target:detailVC_
                                                                                 action:@selector(shareButtonPushed:)];
    
    // Remove the outline around the button to make iOS button look more iOS 7ish
    [shareButton setBackgroundImage:[UIImage imageNamed:@"clear.png"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];

    if (!self.selectedRecord.complete.boolValue) {
        imageScrollVC_.navigationItem.rightBarButtonItem = self.uploadButton;
    }else{
        imageScrollVC_.navigationItem.rightBarButtonItem = shareButton;
    }
}

-(void)popViewControllerAnimated
{
	[self.navigationController popViewControllerAnimated:YES];
}

-(BOOL)shouldAutomaticallyForwardAppearanceMethods
{
    // This method is called to determine whether to
    // automatically forward appearance-related containment
    //  callbacks to child view controllers.
    return YES;
    
}
-(BOOL)shouldAutomaticallyForwardRotationMethods
{
    // This method is called to determine whether to
    // automatically forward rotation-related containment
    // callbacks to child view controllers.
    return YES;
}

-(void)addDetailsViewToImageScrollViewController
{
    detailVC_ = [self.storyboard instantiateViewControllerWithIdentifier:@"DetailScrollViewController"];
    detailVC_.selectedRecord = self.selectedRecord;
    
    imageTapRecognizer_ = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTap:)];
    imageTapRecognizer_.numberOfTouchesRequired = 1;
    imageDoubleTapRecognizer_.numberOfTapsRequired = 1;
    [imageScrollVC_.view addGestureRecognizer:imageTapRecognizer_];
    imageTapRecognizer_.cancelsTouchesInView = NO;
    imageTapRecognizer_.delegate = self;

    imageTwoFingerTapRecognizer_ = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerTap:)];
    imageTwoFingerTapRecognizer_.numberOfTouchesRequired = 2;
    imageTwoFingerTapRecognizer_.numberOfTapsRequired = 1;
    [imageScrollVC_.view addGestureRecognizer:imageTwoFingerTapRecognizer_];
    imageTwoFingerTapRecognizer_.cancelsTouchesInView = NO;
    imageTwoFingerTapRecognizer_.delegate = self;

    imageDoubleTapRecognizer_ = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageDoubleTap:)];
    imageDoubleTapRecognizer_.numberOfTouchesRequired = 1;
    imageDoubleTapRecognizer_.numberOfTapsRequired = 2;
    [imageScrollVC_.view addGestureRecognizer:imageDoubleTapRecognizer_];
    imageDoubleTapRecognizer_.cancelsTouchesInView = NO;
    imageDoubleTapRecognizer_.delegate = self;

    [imageTapRecognizer_ requireGestureRecognizerToFail:imageDoubleTapRecognizer_];

    [imageScrollVC_ addChildViewController:detailVC_];
    [imageScrollVC_.view addSubview:detailVC_.view];

    // Let the detailVC notify the imageScrollVC when the detailVC view slides around
    // This allows the imageScrollVC to adjust its image visibility depending on how
    // far the detailVS view has been slid
    detailVC_.delegate = (ImageScrollViewController<DetailScrollViewControllerDelegate> *)imageScrollVC_;

    [detailVC_ didMoveToParentViewController:imageScrollVC_];
    
    [imageScrollVC_.view bringSubviewToFront:detailVC_.view];
    [detailVC_.view bringSubviewToFront:detailVC_.scrollContainer];
}

-(void)handleImageTap:(UITapGestureRecognizer *)recognizer
{
    // Toggles full-screen image pinch mode
    [detailVC_ toggle];
}

-(void)handleImageDoubleTap:(UITapGestureRecognizer *)recognizer
{
    [imageScrollVC_.imageScrollView setZoomScale:(imageScrollVC_.imageScrollView.zoomScale * 2.0f) animated:YES];
}

-(void)handleTwoFingerTap:(UITapGestureRecognizer *)recognizer
{
    [imageScrollVC_.imageScrollView setZoomScale:[imageScrollVC_ getImageAspectFitScale] animated:YES];
}

@end
