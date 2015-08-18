//
//  MovieDBService.h
//  MMDB
//
//  Created by Rob Wyland on 8/13/15.
//  Copyright (c) 2015 Org Inc. All rights reserved.
//

@class Movie;

/**
 *  A Delegate to receive responses for async network calls.
 */
@protocol MovieLookupDelegate

/**
 *  A list of movies returned for a specific page number.
 */
- (void)receivedMovies:(NSArray *)movies forPage:(NSUInteger)page;

/**
 *  A movie returned for a specific lookup on id.
 *  This will cache movies for quicker responsiveness.
 */
- (void)receivedMovieDetails:(Movie *)movie;

/**
 *  Some sort of failure from the network call.
 */
- (void)requestFailedWithError:(NSError *)error;

@end


/**
 *  A Service to make requests to the Movie Database APIs
 */
@interface MovieDBService : NSObject

@property (weak, nonatomic) id<MovieLookupDelegate> delegate;

/**
 *  Make a request to the popular Movies API
 */
- (void)requestPopularMoviesWithPage:(NSUInteger)page;

/**
 *  Make a request to search for mMvies by a query
 */
- (void)searchMoviesWithQuery:(NSString *)query andPage:(NSUInteger)page;

/**
 *  Make a request to lookup the details of a Movie by id.
 */
- (void)lookupMovieWithId:(NSNumber *)movieId;

@end
