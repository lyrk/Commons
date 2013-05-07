//
//  CategorySearchTableViewController.m
//  Commons-iOS
//
//  Created by Brion on 4/19/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "CategorySearchTableViewController.h"

#define SEARCH_CATS_LIMIT 25

@interface CategorySearchTableViewController ()

@end

@implementation CategorySearchTableViewController

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
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    UINib *cellNib = [UINib nibWithNibName:@"CategoryCell" bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:@"CategoryCell"];
    [self.searchDisplayController.searchResultsTableView registerNib:cellNib forCellReuseIdentifier:@"CategoryCell"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0) {
        if (self.categories) {
            return self.categories.count;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CategoryCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    if (indexPath.section == 0) {
        NSString *cat = self.categories[indexPath.row];
        cell.textLabel.text = cat;
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row < self.categories.count) {
        NSString *cat = self.categories[indexPath.row];
        NSString *encCat = [cat stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *link = [NSString stringWithFormat:@"https://commons.m.wikimedia.org/wiki/Category:%@", encCat];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link]];
    }
}

#pragma mark - Search bar delegate

//- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchText
{
    CommonsApp *app = CommonsApp.singleton;

    // cancel live search
    if (self.api != nil) {
        [self.api cancelCurrentRequest];
    }

    self.api = [app startApi];
    MWPromise *fetch = [self.api getRequest:@{
        @"action": @"query",
        @"list": @"allcategories",
        @"acprefix": searchText,
        @"aclimit": @SEARCH_CATS_LIMIT
    }];
    [fetch done:^(NSDictionary *result) {
        NSMutableArray *categories = [[NSMutableArray alloc] init];
        if (result[@"query"]) {
            for (NSDictionary *entry in result[@"query"][@"allcategories"]) {
                NSString *cat = entry[@"*"]; // yay crappy result formats
                [categories addObject:cat];
            }
        }
        NSLog(@"%@", categories);
        self.categories = [NSArray arrayWithArray:categories];
        [self.tableView reloadData];
        [self.searchDisplayController.searchResultsTableView reloadData];
    }];
    return NO; // async...
}

@end
