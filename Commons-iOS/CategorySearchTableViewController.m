//
//  CategorySearchTableViewController.m
//  Commons-iOS
//
//  Created by Brion on 4/19/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "CategorySearchTableViewController.h"
#import "MWI18N.h"
#import "DetailScrollViewController.h"

#define SEARCH_CATS_LIMIT 25

@interface CategorySearchTableViewController ()

@end

@implementation CategorySearchTableViewController

-(void)backButtonPressed:(id)sender
{
    [self popBackToDetails];
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
    self.navigationItem.leftBarButtonItem = [[CommonsApp singleton] getBackButtonItemWithTarget:self action:@selector(backButtonPressed:)];

    self.recentCats = [self recentCategories]; // don't need a live view, it won't change while we're viewing
    self.searchCats = @[];

    UINib *cellNib = [UINib nibWithNibName:@"CategoryCell" bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:@"CategoryCell"];
        
    [self.searchBar setPlaceholder:[MWMessage forKey:@"catadd-search-placeholder"].text];

    self.searchBar.tintColor = [UIColor blackColor];
    
    self.view.backgroundColor = [UIColor darkGrayColor];

    for (UIView *v in self.tableView.subviews) {
        v.backgroundColor = [UIColor darkGrayColor];
    }
    
    for (UIView *v in self.view.subviews) {
        v.backgroundColor = [UIColor darkGrayColor];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 * Return list of categories as a list of name strings
 */
- (NSArray *)recentCategories
{
    CommonsApp *app = CommonsApp.singleton;
    NSArray *cats = [app recentCategories]; // array of Category objects
    NSMutableArray *names = [[NSMutableArray alloc] init];
    for (CommonsCategory *cat in cats) {
        [names addObject:cat.name];
    }
    return [NSArray arrayWithArray:names];
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
    NSArray *cats;
    if (tableView == self.tableView) {
        cats = self.recentCats;
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        cats = self.searchCats;
    }

    if (section == 0) {
        if (cats) {
            return cats.count;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CategoryCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.backgroundColor = [UIColor darkGrayColor];
    
    for (UIView *v in cell.subviews) {
        v.backgroundColor = [UIColor darkGrayColor];
    }
    
    NSArray *cats;
    if (tableView == self.tableView) {
        cats = self.recentCats;
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        cats = self.searchCats;
    }

    // Configure the cell...
    if (indexPath.section == 0) {
        NSString *cat = cats[indexPath.row];
        cell.textLabel.text = cat;
    }
    
    return cell;
}

-(void)popBackToDetails
{
    // First notify the details controller that it needs to refresh its category list
    UIViewController *prevVC = self.navigationController.viewControllers[self.navigationController.viewControllers.count - 2];
    // Details is a child of ImageScrollViewController, which should be prevVC
    for (UIViewController *vc in prevVC.childViewControllers) {
        if ([vc isMemberOfClass:[DetailScrollViewController class]]) {
            // Notifies details view controller that it needs to refresh its category layout after it appears.
            // (Needs to do so after it appears so layout its layout constraints don't go bonkers.)
            [(DetailScrollViewController *)vc setCategoriesNeedToBeRefreshed:YES];
        }
    }
    // updateCategoryContainer causes the details view to reflect any new category selections
    //    [details updateCategoryContainer];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *cats;
    if (tableView == self.tableView) {
        cats = self.recentCats;
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        cats = self.searchCats;
    }
    
    if (indexPath.section == 0) {
        NSString *cat = cats[indexPath.row];
        [self.selectedRecord addCategory:cat];
        [CommonsApp.singleton updateCategory:cat];
        [CommonsApp.singleton saveData];
        [self popBackToDetails];
    }
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NSArray *cats;
    if (tableView == self.tableView) {
        cats = self.recentCats;
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        cats = self.searchCats;
    }

    if (indexPath.section == 0 && indexPath.row < cats.count) {
        NSString *cat = cats[indexPath.row];
        NSString *encCat = [cat stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *link = [NSString stringWithFormat:@"https://commons.m.wikimedia.org/wiki/Category:%@", encCat];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link]];
    }
}

#pragma mark - Search display controller delegate

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    UINib *cellNib = [UINib nibWithNibName:@"CategoryCell" bundle:nil];
    [tableView registerNib:cellNib forCellReuseIdentifier:@"CategoryCell"];
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchText
{
    CommonsApp *app = CommonsApp.singleton;

    [controller.searchResultsTableView setBackgroundColor:[UIColor darkGrayColor]];

    // cancel live search
    if (self.api != nil) {
        [self.api cancelCurrentRequest];
    }

    // fixme: this search is case-sensitive, which is an issue!
    // it also turns up categories that should be empty... not sure how to best improve this.
    self.api = [app startApi];
    MWPromise *fetch = [self.api getRequest:@{
        /*@"action": @"query",
        @"list": @"allcategories",
        @"acprefix": searchText,
        @"aclimit": @SEARCH_CATS_LIMIT*/
        @"action": @"query",
        @"list": @"allpages",
        @"apfrom": searchText,
        @"apprefix": searchText,
        @"apnamespace": @"14",
        @"aplimit": @SEARCH_CATS_LIMIT
                                              
    }];
    [fetch done:^(NSDictionary *result) {
        NSMutableArray *categories = [[NSMutableArray alloc] init];
        if (result[@"query"]) {
            for (NSDictionary *entry in result[@"query"][@"allpages"]) {
                NSString *cat = [entry[@"title"] stringByReplacingOccurrencesOfString:@"Category:" withString: @"" options:NSLiteralSearch range:[entry[@"title"] rangeOfString:@"Category:"]];
                [categories addObject:cat];
            }
        }
        NSLog(@"%@", categories);
        self.searchCats = [NSArray arrayWithArray:categories];
        [self.tableView reloadData];
        [self.searchDisplayController.searchResultsTableView reloadData];
    }];
    return NO; // async...
}

@end
