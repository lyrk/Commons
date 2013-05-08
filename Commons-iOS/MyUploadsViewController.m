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
#import "DetailTableViewController.h"
#import "MWI18N/MWI18N.h"
#import "Reachability.h"
#import "SettingsViewController.h"
#import "WelcomeOverlayView.h"
#import "FetchImageOperation.h"

#define OPAQUE_VIEW_ALPHA 0.7
#define OPAQUE_VIEW_BACKGROUND_COLOR blackColor
#define BUTTON_ANIMATION_DURATION 0.25

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface MyUploadsViewController () {
    NSString *pickerSource_;
    UITapGestureRecognizer *tapRecognizer;
    bool buttonAnimationInProgress;
    UIView *opaqueView;
    NSUInteger thumbnailCount;
    //NSOperationQueue *fetchThumbQueue;
}

- (void)animateTakeAndChoosePhotoButtons;
- (void)refreshImages;
- (BOOL)isOpCellOnScreen:(FetchImageOperation *)op;
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
- (void)raiseDowloadPriorityForImagesOfOnscreenCells;

@end

@implementation MyUploadsViewController

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        thumbnailCount = 0;
        //fetchThumbQueue = [[NSOperationQueue alloc] init];

        CommonsApp *app = [CommonsApp singleton];
        
        // Observe changes to the number of items in the fetch queue
        [app.fetchDataURLQueue addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (thumbnailCount != 0){
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

    // Set up refresh
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshButtonPushed:)
             forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.refreshControl];

    // l10n
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:[MWMessage forKey:@"contribs-refresh"].text];
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
	tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideTakeAndChoosePhotoButtons:)];
    
    // By not cancelling touches in view the tapping the images in the background will cause the tapped image details view to load
    [tapRecognizer setCancelsTouchesInView:NO];
    
    // Makes "gestureRecognizer:shouldReceiveTouch:" be called so decisions may be made about which interface elements respond to tapRecognizer touches
    [tapRecognizer setDelegate:self];
    
	[self.view addGestureRecognizer:tapRecognizer];
    
    buttonAnimationInProgress = NO;

    // This view is used to fade out the background when the take and choose photo buttons are revealed
    opaqueView = [[UIView alloc] init];
    opaqueView.backgroundColor = [UIColor clearColor];
    
    // Make the About and Settings buttons stand out better against light colors
    self.settingsButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.settingsButton.layer.shadowOpacity = 1.0;
    self.settingsButton.layer.shadowRadius = 4;
    self.settingsButton.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    
    self.aboutButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.aboutButton.layer.shadowOpacity = 1.0;
    self.aboutButton.layer.shadowRadius = 4;
    self.aboutButton.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
}

-(BOOL)hasCamera
{
    return [UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    // Make sure when the device is rotated that the opaqueView changes dimensions accordingly
    opaqueView.frame = self.view.bounds;

    // UIViews don't have access to self.interfaceOrientation, this gets around that so the
    // welcomeOverlayView can adjust its custom drawing when it needs to
    self.welcomeOverlayView.interfaceOrientation = self.interfaceOrientation;
}

-(void)reachabilityChange:(NSNotification*)note {
    Reachability * reach = [note object];
    NetworkStatus netStatus = [reach currentReachabilityStatus];
    if (netStatus == ReachableViaWiFi || netStatus == ReachableViaWWAN)
    {
        self.uploadButton.enabled = YES;
    }
    else if (netStatus == NotReachable)
    {
        self.uploadButton.enabled = NO;
    }
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
    // Prevent the overlay message from flickering as the view disappears
    [self.welcomeOverlayView showMessage:WELCOME_MESSAGE_NONE];
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

    self.popover = nil;
    self.selectedRecord = nil;

    [self setAddMediaButton:nil];
    [self setTakePhotoButton:nil];
    [self setChoosePhotoButton:nil];
    [self setCollectionView:nil];
    [super viewDidUnload];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"DetailSegue"]) {
        DetailTableViewController *view = [segue destinationViewController];
        view.selectedRecord = self.selectedRecord;
    }
}

#pragma mark - Thumb Download Prioritization

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
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
    
    CommonsApp *app = CommonsApp.singleton;
    for (NSIndexPath *indexPath in [self.collectionView indexPathsForVisibleItems]) {
        FileUpload *record = (FileUpload *)[app.fetchedResultsController objectAtIndexPath:indexPath];
        
        // The title has had its underscores replaces with spaces, so to match the title to the url
        // the url must do the same
        NSString *urlNoUnderscore = [[op.url path] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
        
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
        
        _uploadButton = [[UIBarButtonItem alloc] initWithTitle:@"Upload"
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(uploadButtonPushed:)];
    }
    
    return _uploadButton;
}

- (UIBarButtonItem *)cancelButton {
    
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
        
        if ([app.fetchedResultsController.fetchedObjects count] > 0) {
            
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
    
    MWPromise *refresh = [CommonsApp.singleton refreshHistory];
    
    // Make refresh control say "Refreshing..."
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:[MWMessage forKey:@"contribs-refreshing"].text];
    [refresh always:^(id arg) {
        [self.refreshControl endRefreshing];
        
        // Wait just a second before switching back to the "Pull to refresh" text so the refresh control has
        // time to hide itself first. Otherwise it just looks a bit odd to see it flash to the "Pull to
        // refresh" text just before it hides.
        int64_t delayInSeconds = 1.0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
            // Executed on the main queue after delay
            self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:[MWMessage forKey:@"contribs-refresh"].text];
        });
        
        // Now that the refresh is done it is known whether there are images, so show the welcome message if needed
        if (thumbnailCount == 0) {
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
	
	[UIView animateWithDuration:0.2
						  delay:0.0
						options:UIViewAnimationOptionTransitionNone
					 animations:^{

						 // Spin and enlarge the settings button briefly up tapping it
						 self.settingsButton.transform = CGAffineTransformRotate(CGAffineTransformMakeScale(1.8, 1.8), DEGREES_TO_RADIANS(180));

					 }
					 completion:^(BOOL finished){

						 // Reset the settings button transform
						 self.settingsButton.transform = CGAffineTransformIdentity;
						 
						 // Push the settings view controller on to the nav controller now that the little animation is done
						 SettingsViewController *settingsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingsViewController"];
						 [self.navigationController pushViewController:settingsVC animated:YES];

					 }];
}

- (IBAction)addMediaButtonPushed:(id)sender {
    
    // Ensure the toggle can't be toggled again until any animation from a previous toggle has completed
    if (buttonAnimationInProgress) return;
    
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

        // Make the opaque view appear, presently it's transparent, but its color transition will be animated along with the button location changes below
        // (also ensure the buttons are on top of the opaque view)
        [self.view addSubview:opaqueView];
        [self.view bringSubviewToFront:opaqueView];
        [self.view bringSubviewToFront:self.takePhotoButton];
        [self.view bringSubviewToFront:self.choosePhotoButton];
        [self.view bringSubviewToFront:self.addMediaButton];
        
        // Run the "show buttons" animation (first move the take and choose buttons to the add media button position)
        takePhotoButtonOriginalCenter = self.takePhotoButton.center;
        choosePhotoButtonOriginalCenter = self.choosePhotoButton.center;
        self.takePhotoButton.center = self.addMediaButton.center;
        self.choosePhotoButton.center = self.addMediaButton.center;
        
        //make the take and choose buttons twist as they're revealed and hidden
        self.takePhotoButton.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-90));
        self.choosePhotoButton.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(90));
        
        [UIView animateWithDuration:BUTTON_ANIMATION_DURATION
                              delay:0.0
                            options:UIViewAnimationOptionTransitionNone
                         animations:^{
                             // Animate the take and choose buttons to their original storyboard positions
                             self.takePhotoButton.center = takePhotoButtonOriginalCenter;
                             self.choosePhotoButton.center = choosePhotoButtonOriginalCenter;
                             self.takePhotoButton.hidden = NO;
                             self.choosePhotoButton.hidden = NO;
                             buttonAnimationInProgress = YES;

                             self.takePhotoButton.transform = CGAffineTransformIdentity;
                             self.choosePhotoButton.transform = CGAffineTransformIdentity;
                             
                            // Also animate the opaque view from transparent to partially opaque
                            [opaqueView setAlpha:OPAQUE_VIEW_ALPHA];
                            opaqueView.backgroundColor = [UIColor OPAQUE_VIEW_BACKGROUND_COLOR];
                             
                         }
                         completion:^(BOOL finished){
                             self.takePhotoButton.enabled = [self hasCamera];
                             self.choosePhotoButton.enabled = YES;
                             buttonAnimationInProgress = NO;
                             
                             // Now that the addMediaButton was tapped, change the welcome message to
                             // describe the take and choose photo buttons. Only do so if the user has
                             // no images
                             if(thumbnailCount == 0){
                                 [self.welcomeOverlayView showMessage:WELCOME_MESSAGE_CHOOSE_OR_TAKE];
                             }
                         }];
    }else{
        
        // Assuming a user with no images may need a little prompting, show a welcome message
        if(thumbnailCount == 0) [self.welcomeOverlayView showMessage:WELCOME_MESSAGE_WELCOME];
        
        // Run the "hide buttons" animation, essentially unwinding the animations above
        takePhotoButtonOriginalCenter = self.takePhotoButton.center;
        choosePhotoButtonOriginalCenter = self.choosePhotoButton.center;
        [UIView animateWithDuration:BUTTON_ANIMATION_DURATION
                              delay:0.0
                            options:UIViewAnimationOptionTransitionNone
                         animations:^{
                            self.takePhotoButton.center = self.addMediaButton.center;
                            self.choosePhotoButton.center = self.addMediaButton.center;
                            buttonAnimationInProgress = YES;

                            [opaqueView setAlpha:1.0];
                            opaqueView.backgroundColor = [UIColor clearColor];
                             
                             self.takePhotoButton.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-90));
                             self.choosePhotoButton.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(90));
                             
                             //make the add media button swell as the take and choose buttons are hidden - almost makes it appear to swallow them
                             self.addMediaButton.transform = CGAffineTransformMakeScale(1.25, 1.25);
                             
                         }
                         completion:^(BOOL finished){
                            self.takePhotoButton.hidden = YES;
                            self.choosePhotoButton.hidden = YES;
                            self.takePhotoButton.center = takePhotoButtonOriginalCenter;
                            self.choosePhotoButton.center = choosePhotoButtonOriginalCenter;
                            self.addMediaButton.transform = CGAffineTransformIdentity;
                            buttonAnimationInProgress = NO;

                            [opaqueView removeFromSuperview];
                         }];
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
    if (gestureRecognizer == tapRecognizer) {
        
        if (buttonAnimationInProgress) return NO;
        if (touch.view == self.addMediaButton) return NO;
        if (touch.view == self.takePhotoButton) return NO;
        if (touch.view == self.choosePhotoButton) return NO;
    }
    
    return YES;
}

-(BOOL)shouldAutorotate
{
    // Don't auto rotate if animateTakeAndChoosePhotoButtons is currently moving the buttons
    // This is needed because the button animation code relies on the storyboard button locations
    // and these button locations are changed by when the device rotates
    return (!buttonAnimationInProgress);
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
    self.choosePhotoButton.hidden = YES;
    self.takePhotoButton.hidden = YES;
}


#pragma mark - UICollectionViewDelegate methods

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
        return CGSizeMake(256.0f - 2.0f, 240.0f);
    } else {
        // iPhone/iPod: fit 1 across in portrait, 2 across in landscape
        CGSize screenSize = UIScreen.mainScreen.bounds.size;
        if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
            return CGSizeMake(screenSize.width, 240.0f);
        } else {
            return CGSizeMake(screenSize.height / 2.0f - 1.0f, 240.0f);
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
    
    thumbnailCount = count;

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
    
    NSString *indexPosition = [NSString stringWithFormat:@"%d", indexPath.item + 1];
    cell.indexLabel.text = indexPosition;
    // fixme indexPosition doesn't always update when we add new items

    NSString *title = record.title;

    if (cell.title && [cell.title isEqual:title]) {
        // Image should already be loaded.
        NSLog(@"already loaded a title");
    } else {
        // Save the title for future checks...
        cell.title = title;
        
        cell.image.image = nil;
        
        // Using fetchThumbQueue below eliminates the last bit of jitter when scrolling through a large image set, but
        // it's causing strange intermittent (threading related?) errors - commented for now until it can be further debugged...
        
        // Fetch the thumbnail on a background thread
        //[fetchThumbQueue addOperationWithBlock:^{
        MWPromise *fetchThumb = [record fetchThumbnail];
        
        [fetchThumb done:^(UIImage *image) {
            // Now that the thumbnail has been fetched use it - do so on the main thread
            //[[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if ([cell.title isEqualToString:title]) {
                if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad){
                    // Smooth transition (disabled on iPad for better performance - iPad shows many more images at once)
                    CATransition *transition = [CATransition animation];
                    transition.duration = 0.10f;
                    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
                    transition.type = kCATransitionFade;
                    [cell.image.layer addAnimation:transition forKey:nil];
                }
                cell.image.image = image;
            }
            //}];
        }];
        [fetchThumb fail:^(NSError *error) {
            //[[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSLog(@"failed to load thumbnail");
            //}];
        }];
        //}];
    }
    if (record.complete.boolValue) {
        // Old upload, already complete.
        cell.titleLabel.text = record.title;
        cell.statusLabel.text = @"";
        cell.progressBar.hidden = YES;
    } else {
        // Queued upload, not yet complete.
        // We have local data & progress info.
        cell.titleLabel.text = record.title;
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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Clear out the lines as they are invalid for the new orientation
    [self.welcomeOverlayView clearLines];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // Update collectionview cell size for iPhone/iPod
    [self.collectionView.collectionViewLayout invalidateLayout];

    // Update the lines for the new orientation
    [self.welcomeOverlayView animateLines];
}

#pragma mark UIScrollViewDelegate methods

/*
 - (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSLog(@"blah");
}
*/

@end
