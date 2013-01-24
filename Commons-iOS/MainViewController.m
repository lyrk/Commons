//
//  MainViewController.m
//  Commons-iOS
//
//  Created by Brion on 1/7/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "MainViewController.h"
#import "AppDelegate.h"
#import "mwapi/MWApi.h"

@interface MainViewController ()
@property (weak, nonatomic) AppDelegate *appDelegate;
@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        // Camera is available
    } else {
        // Clicking 'take photo' in simulator *will* crash, so disable the button.
        // FIXME this doesn't take effect for some reason!
        [self.TakePhotoButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
        self.TakePhotoButton.enabled = NO;
    }
    self.progressBar.hidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Flipside View

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        [[segue destinationViewController] setDelegate:self];
    }
}

- (void)viewDidUnload {
    [self setTakePhotoButton:nil];
    [self setGalleryButton:nil];
    [self setDescriptionTextView:nil];
    [self setUploadButton:nil];
    [self setImagePreview:nil];
    [self setProgressBar:nil];
    [self setActivityIndicator:nil];
    [super viewDidUnload];
}

- (IBAction)pushedPhotoButton:(id)sender {
    NSLog(@"Take photo");
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)pushedGalleryButton:(id)sender {
    NSLog(@"Open gallery");
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)pushedUploadFiles:(id)sender {
    NSLog(@"Upload ye files!");

    NSString *username = self.appDelegate.username;
    NSString *password = self.appDelegate.password;
    NSString *desc = self.DescriptionTextView.text;
    NSString *filename = [NSString stringWithFormat:@"Testfile %li.jpg", (long)[[NSDate date] timeIntervalSince1970]];
    UIImage *image = self.imagePreview.image;
    NSData *jpeg = UIImageJPEGRepresentation(image, 0.9);

    NSLog(@"username: %@, desc: %@, jpeg: %i bytes", username, desc, (int)(jpeg.length));
    
    // hack hack hack
    // Upload the file
    NSURL *url = [NSURL URLWithString:@"https://test2.wikipedia.org/w/api.php"];
    MWApi *mwapi = [[MWApi alloc] initWithApiUrl:url];

    // Run an indeterminate activity indicator during login validation...
    [self.activityIndicator startAnimating];
    [mwapi loginWithUsername:username andPassword:password withCookiePersistence:YES onCompletion:^(MWApiResult *loginResult) {
        NSLog(@"login: %@", loginResult.data[@"login"][@"result"]);
        [self.activityIndicator stopAnimating];
        if (mwapi.isLoggedIn) {
            [self.progressBar setProgress:0.0f];
            self.progressBar.hidden = NO;
            void (^progress)(NSInteger, NSInteger) = ^(NSInteger bytesSent, NSInteger bytesTotal) {
                self.progressBar.progress = (float)bytesSent / (float)bytesTotal;
            };
            void (^complete)(MWApiResult *) = ^(MWApiResult *uploadResult) {
                NSLog(@"upload: %@", uploadResult.data);
                
                NSLog(@"done uploading...");
                self.progressBar.hidden = YES;
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
    self.imagePreview.image = info[UIImagePickerControllerOriginalImage];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSLog(@"canceled");
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Hide keyboard when hitting 'done'
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
{
    if ([text isEqualToString: @"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

@end
