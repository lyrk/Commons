//
//  CategorySearchTableViewController.h
//  Commons-iOS
//
//  Created by Brion on 4/19/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonsApp.h"

@interface CategorySearchTableViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (strong) MWApi *api;
@property (strong) NSArray *recentCats;
@property (strong) NSArray *searchCats;
@property (strong) FileUpload *selectedRecord;

@end
