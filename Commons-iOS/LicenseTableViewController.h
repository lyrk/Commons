//
//  LicenseTableViewController.h
//  Commons-iOS
//
//  Created by Brion on 4/18/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LicenseTableViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UIButton *ccBySaViewButton;
- (IBAction)pushLicenseButton:(id)sender;

@end
