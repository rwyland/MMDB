//
//  MovieDetailsViewController.m
//  MMDB
//
//  Created by Rob Wyland on 8/13/15.
//  Copyright (c) 2015 Org Inc. All rights reserved.
//

#import "MovieDetailsViewController.h"
#import "Movie.h"
#import "StarView.h"
#import "MoviePosterUtil.h"

@interface MovieDetailsViewController ()

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *yearLabel;
@property (strong, nonatomic) IBOutlet UILabel *durationLabel;
@property (strong, nonatomic) IBOutlet UILabel *voteCountLabel;

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet StarView *starView;

@property (strong, nonatomic) IBOutlet UITextView *descriptionView;

@end

@implementation MovieDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Using background colors in IB to see visual frames
    // Overriding them here or can just reset them in the NIB to remove this code
    [self.titleLabel setBackgroundColor:[UIColor clearColor]];
    [self.yearLabel setBackgroundColor:[UIColor clearColor]];
    [self.durationLabel setBackgroundColor:[UIColor clearColor]];
    [self.voteCountLabel setBackgroundColor:[UIColor clearColor]];
    [self.descriptionView setBackgroundColor:[UIColor clearColor]];
    [self.imageView setBackgroundColor:[UIColor clearColor]];
    [self.starView setBackgroundColor:[UIColor clearColor]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.movie) {
        [self.titleLabel setText:self.movie.title];
        [self.yearLabel setText:self.movie.year];
        [self.durationLabel setText:self.movie.duration];
        [self.voteCountLabel setText:[NSString stringWithFormat:@"%i votes", self.movie.vote_count.intValue]];
        [self.descriptionView setText:self.movie.overview];
        [MoviePosterUtil loadPosterForMovie:self.movie intoView:self.imageView];
        [self.starView setRating:self.movie.rating];
    }
}

@end
