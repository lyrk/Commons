//
//  MainViewController.h
//  Commons-iOS
//
//  Created by Brion on 1/7/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "FlipsideViewController.h"

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *TakePhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *GalleryButton;
@property (weak, nonatomic) IBOutlet UITextView *DescriptionTextView;
@property (weak, nonatomic) IBOutlet UIButton *UploadButton;
@property (weak, nonatomic) IBOutlet UIImageView *imagePreview;

- (IBAction)pushedPhotoButton:(id)sender;
- (IBAction)pushedGalleryButton:(id)sender;
- (IBAction)pushedUploadFiles:(id)sender;

@end
