//
//  CategoryDetailTableViewController.m
//  Commons-iOS
//
//  Created by Brion on 5/7/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "CategoryDetailTableViewController.h"
#import "MWI18N.h"

@interface CategoryDetailTableViewController ()

@end

@implementation CategoryDetailTableViewController

-(void)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

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
    
    // Change back button to be an arrow
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[[CommonsApp singleton] getBackButtonString]
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:self
                                                                            action:@selector(backButtonPressed:)];

    // i18n
    self.removeLabel.text = [MWMessage forKey:@"catdetail-remove-label" param:self.category].text;
    self.moreLabel.text = [MWMessage forKey:@"catdetail-info-label"].text;

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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    if (indexPath.section == 0) {
        // 'Remove' button
        [self.selectedRecord removeCategory:self.category];
        [CommonsApp.singleton saveData];
        [self.navigationController popViewControllerAnimated:YES];
    } else if (indexPath.section == 1) {
        // 'Read about categories' button
        NSString *link = [MWMessage forKey:@"catdetail-info-url"].text;
        [CommonsApp.singleton openURLWithDefaultBrowser:[NSURL URLWithString:link]];
    }
}

// fixme i18nize the section headings

@end
