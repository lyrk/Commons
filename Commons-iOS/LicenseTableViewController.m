//
//  LicenseTableViewController.m
//  Commons-iOS
//
//  Created by Brion on 4/18/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "LicenseTableViewController.h"
#import "MWI18N.h"

@interface LicenseTableViewController ()

@end

@implementation LicenseTableViewController

#define TABLESECTION_LICENSE 0
#define TABLESECTION_MORE    1

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = [MWMessage forKey:@"license-title"].text;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == TABLESECTION_LICENSE) {
        return [MWMessage forKey:@"license-intro"].text;
    } else if (section == TABLESECTION_MORE) {
        return [MWMessage forKey:@"license-details-intro"].text;
    }
    return @"";
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = [indexPath indexAtPosition:0];

    if (section == TABLESECTION_LICENSE) {
        // todo: add support for multiple license variants :)
        
        // set a checkmark on the selected item...
        // todo ^
    } else if (section == TABLESECTION_MORE) {
        NSString *link = [MWMessage forKey:@"license-details-url"].text;
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link]];
    }

    // ... then deselect the item in the table.
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)openLicense
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://creativecommons.org/licenses/by-sa/3.0/"]];
}


- (IBAction)pushLicenseButton:(id)sender {
    [self openLicense];
}
@end
