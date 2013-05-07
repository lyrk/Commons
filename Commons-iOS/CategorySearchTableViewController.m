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
    
    self.recentCats = @[@"San Francisco", @"Test", @"Zimbabwe"]; // todo store recent cats
    self.searchCats = @[];
    
    UINib *cellNib = [UINib nibWithNibName:@"CategoryCell" bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:@"CategoryCell"];
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
        [CommonsApp.singleton saveData];

        [self.navigationController popViewControllerAnimated:YES];
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

    // cancel live search
    if (self.api != nil) {
        [self.api cancelCurrentRequest];
    }

    // fixme: this search is case-sensitive, which is an issue!
    // it also turns up categories that should be empty... not sure how to best improve this.
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
        self.searchCats = [NSArray arrayWithArray:categories];
        [self.tableView reloadData];
        [self.searchDisplayController.searchResultsTableView reloadData];
    }];
    return NO; // async...
}

@end
