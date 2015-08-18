//
//  Movie.h
//  MMDB
//
//  Created by Rob Wyland on 8/13/15.
//  Copyright (c) 2015 Org Inc. All rights reserved.
//

/**
 * A model to represent the details of a movie that we will use for Views and Controllers.
 */
@interface Movie : NSObject

@property (strong, nonatomic) NSNumber *id;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *poster_path;
@property (strong, nonatomic) NSString *release_date;
@property (strong, nonatomic) NSNumber *runtime;
@property (strong, nonatomic, getter=overview) NSString *overview;
@property (strong, nonatomic) NSNumber *vote_average;
@property (strong, nonatomic) NSNumber *vote_count;

/**
 *  Massage the release_date into a view-friendly year.
 */
- (NSString *)year;

/**
 *  Massage the runtime into a view-friendly hour and min duration.
 */
- (NSString *)duration;

/**
 * Massage the vote_average into a view-friendly rating.
 */
- (NSString *)rating;

@end
