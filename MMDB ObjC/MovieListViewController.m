//
//  MovieListViewController.m
//  MMDB
//
//  Created by Rob Wyland on 8/13/15.
//  Copyright (c) 2015 Org Inc. All rights reserved.
//

#import "MovieListViewController.h"
#import "MovieDetailsViewController.h"
#import "MovieDBService.h"
#import "MoviePosterUtil.h"
#import "Movie.h"

#define kHOT_TITLE @"What's Hot!"
#define kSEARCH_TITLE @"Search"

@interface MovieListViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, MovieLookupDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *moviesDatasource;

@property (strong, nonatomic) MovieDBService *movieDBService;

@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) NSString *query;
@property (nonatomic, assign) BOOL isSearching;

@end

@implementation MovieListViewController

#pragma mark - Init

- (instancetype)init {
    if ( self = [super init] ) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ( self = [super initWithCoder:aDecoder] ) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ( self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil] ) {
        [self initialize];
    }
    return self;
}

/**
 *  Make sure the private instance variables are correctly initialized, no matter the implementation method
 */
- (void)initialize {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _movieDBService = [[MovieDBService alloc] init];
    _moviesDatasource = [NSMutableArray array];
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.f, 0.f, 200.f, 40.f)];
    _isSearching = NO;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:_tableView];
    [self.tableView setFrame:self.view.bounds];
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    
    [self.movieDBService setDelegate:self];
    [self.movieDBService requestPopularMoviesWithPage:1];
    
    [self.navigationItem setTitle:kHOT_TITLE];
    UIBarButtonItem *search = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(onSearch:)];
    [self.navigationItem setRightBarButtonItem:search];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

#pragma mark - TableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 150.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // TODO: This request can appear to "hang" if the network is slow or even offline. Ideally we want to provide feedback
    Movie *movie = self.moviesDatasource[indexPath.row];
    [self.movieDBService lookupMovieWithId:movie.id];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Once we are getting near the bottom, go ahead and load the next page into the stack
    // If we are on the last page, the next page will return an empty array in the delegate call
    if ( indexPath.row >= self.moviesDatasource.count - 1 ) {
        NSUInteger nextPage = (self.moviesDatasource.count / 20) + 1;
        // TODO: This request can appear to "hang" if the network is slow or even offline. Ideally we want to provide feedback
        self.isSearching ? [self.movieDBService searchMoviesWithQuery:self.query andPage:nextPage] : [self.movieDBService requestPopularMoviesWithPage:nextPage];
    }
}

#pragma mark - TableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.moviesDatasource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Using a simple layout with some slight modifications.
    // This could always use a subclass of UITableCell to use a custom design with more info like movie rating or vote rating
    static NSString *cellIdentifier = @"MovieCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        [cell.textLabel setFont:[UIFont systemFontOfSize:24.f]];
        [cell.textLabel setNumberOfLines:3];
        [cell.detailTextLabel setFont:[UIFont systemFontOfSize:18.f]];
        [cell.detailTextLabel setTextColor:[UIColor colorWithWhite:0.35f alpha:1.f]];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
    
    Movie *movie = self.moviesDatasource[indexPath.row];
    [cell.textLabel setText:movie.title];
    [cell.detailTextLabel setText:movie.year];
    [MoviePosterUtil loadThumbnailPosterForMovie:movie intoView:cell.imageView];
    
    return cell;
}

#pragma mark - Search Bar Delegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    // Add a grey effect and don't allow scrolling, this could also be done with an animation
    [self.tableView setAlpha:0.5f];
    [self.tableView setUserInteractionEnabled:NO];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    // remove grey effect and allow scrolling, this could also be done with an animation
    [self.tableView setAlpha:1.f];
    [self.tableView setUserInteractionEnabled:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    if ( searchBar.text && searchBar.text.length ) {
        [self searchBarTextDidEndEditing:searchBar];
        self.isSearching = YES;
        self.query = [searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self.movieDBService searchMoviesWithQuery:self.query andPage:1];
    }
}

#pragma mark - Movie DB Delegate

- (void)receivedMovies:(NSArray *)movies forPage:(NSUInteger)page {
    if ( movies.count == 0 && page == 1 ) {
        // The contents are empty, provide feedback to the user
        // We probably dont want to be annoying with an alert, so something like using the table footer would also work
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Results" message:@"please try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        });
        return;
    } else if ( movies.count == 0 ) {
        // Empty page, nothing new to show so do nothing
        return;
    } else if ( page == 1 ) {
        // Start over, new request!
        [self.moviesDatasource removeAllObjects];
    }
    [self.moviesDatasource addObjectsFromArray:movies];
    
    // Always reload the view on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)receivedMovieDetails:(Movie *)movie {
    // Always make changes to the view heiarchy on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        MovieDetailsViewController *detailsVC = [[MovieDetailsViewController alloc] initWithNibName:@"MovieDetailsViewController" bundle:[NSBundle mainBundle]];
        [detailsVC setMovie:movie];
        [self.navigationController pushViewController:detailsVC animated:YES];
    });
}

- (void)requestFailedWithError:(NSError *)error {
    // An error happened, let the user know!
    // Ideally we would want user friendly messages, with some sort of next-step for the user to try
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Fail" message:error.description delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    });
}

#pragma mark - Controller Actions

- (void)onSearch:(id)sender {
    // Swap search with a cancel button
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancel:)];
    [self.navigationItem setRightBarButtonItem:cancel animated:YES];

    // This could also have an animation
    [self.navigationItem setTitle:kSEARCH_TITLE];
    [self.navigationItem setTitleView:self.searchBar];
    [self.searchBar setDelegate:self];
    [self.searchBar becomeFirstResponder];
}

- (void)onCancel:(id)sender {
    // Swap cancel with a search button
    UIBarButtonItem *search = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(onSearch:)];
    [self.navigationItem setRightBarButtonItem:search];
    
    // This could also have an animation
    [self.navigationItem setTitle:kHOT_TITLE];
    [self.navigationItem setTitleView:nil];
    [self.searchBar setDelegate:nil];
    
    // Switch back to the popular results
    self.isSearching = NO;
    self.query = nil;
    [self.movieDBService requestPopularMoviesWithPage:1];
}

@end
