//
//  CategoryDetailTableViewController.h
//  Commons-iOS
//
//  Created by Brion on 5/7/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonsApp.h"

@interface CategoryDetailTableViewController : UITableViewController

@property (strong) NSString *category;
@property (strong) FileUpload *selectedRecord;

@property (weak, nonatomic) IBOutlet UILabel *removeLabel;
@property (weak, nonatomic) IBOutlet UILabel *moreLabel;

@end
