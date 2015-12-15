//
//  MovieDBService.m
//  MMDB
//
//  Created by Rob Wyland on 8/13/15.
//  Copyright (c) 2015 Org Inc. All rights reserved.
//

#import "MovieDBService.h"
#import "Movie.h"

@interface MovieDBService ()

/**
 *  A queue to support network calls on a background thread
 */
@property (strong, nonatomic) NSOperationQueue *queue;

/**
 *  A simple cache by movie id. 
 *  All of the contents of a movie are historical, however the user rating and voting can change, so ideally we would support updating the cache.
 *  We could accomplish this by immediately returning the cache value, and then applying an update to the View if the cache was found to be stale.
 */
@property (strong, nonatomic) NSMutableDictionary *movieCache;

/**
 *  This is loaded from a local plist called "apiKey.plist" with a single string entry:
 *  { @"kAPI_KEY" : @"Your API key" }
 */
@property (strong, nonatomic) NSString *apiKey;

@end

@implementation MovieDBService

#pragma mark - Init

- (instancetype)init {
    if ( self = [super init] ) {
        _queue = [[NSOperationQueue alloc] init];
        _movieCache = [NSMutableDictionary dictionary];
        
        // Find out the path of the local api key properties list
        NSString *path = [[NSBundle mainBundle] pathForResource:@"apiKey" ofType:@"plist"];
        NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:path];
        if ( dict != nil ) {
            _apiKey = dict[@"kAPI_KEY"];
        }
    }
    return self;
}

#pragma mark - Declared Request Methods

- (void)requestPopularMoviesWithPage:(NSUInteger)page {
    NSAssert(self.apiKey != nil, @"An API_KEY is required to use the movie DB. Please register a key as described");

    if ( page > 1000 ) {
        // The API doesn't support anything over 1000
        [self.delegate requestFailedWithError:[NSError errorWithDomain:@"Invalid page number" code:400 userInfo:nil]];
        return;
    }
    
    NSString *urlAsString = [NSString stringWithFormat:@"http://api.themoviedb.org/3/movie/popular?api_key=%@&page=%lu", self.apiKey, (unsigned long)page];
    NSURL *url = [[NSURL alloc] initWithString:urlAsString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:self.queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error || data == nil) {
            [self.delegate requestFailedWithError:error];
            return;
        }
    
        // Parse the raw JSON into Objects
        NSDictionary *parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if ( error ) {
            [self.delegate requestFailedWithError:error];
            return;
        }
        
        NSNumber *page = parsed[@"page"];
        // These can be useful for displaying in the View
        // NSNumber *totalPages = parsed[@"total_pages"];
        // NSNumber *totalResults = parsed[@"total_results"];
        NSMutableArray *movies = [NSMutableArray arrayWithCapacity:20];
        for ( NSDictionary *dict in parsed[@"results"] ) {
            Movie *movie = [self parseMovieFromDictionary:dict];
            [movies addObject:movie];
        }
    
        [self.delegate receivedMovies:movies forPage:page.integerValue];
    }];
}

- (void)searchMoviesWithQuery:(NSString *)query andPage:(NSUInteger)page {
    NSAssert(self.apiKey != nil, @"An API_KEY is required to use the movie DB. Please register a key as described");

    if ( page > 1000 ) {
        // The API doesn't support anything over 1000
        [self.delegate requestFailedWithError:[NSError errorWithDomain:@"Invalid page number" code:400 userInfo:nil]];
        return;
    }
    
    NSString *encoded = [self urlEncodeQuery:query];
    NSString *urlAsString = [NSString stringWithFormat:@"http://api.themoviedb.org/3/search/movie?api_key=%@&query=%@&page=%lu", self.apiKey, encoded, (unsigned long)page];
    NSURL *url = [[NSURL alloc] initWithString:urlAsString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:self.queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error || data == nil) {
            [self.delegate requestFailedWithError:error];
            return;
        }
        
        // Parse the raw JSON into Objects
        NSDictionary *parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if ( error ) {
            [self.delegate requestFailedWithError:error];
            return;
        }
        
        NSNumber *page = parsed[@"page"];
        // These can be useful for displaying in the View
        // NSNumber *totalPages = parsed[@"total_pages"];
        // NSNumber *totalResults = parsed[@"total_results"];
        NSMutableArray *movies = [NSMutableArray arrayWithCapacity:20];
        for ( NSDictionary *dict in parsed[@"results"] ) {
            Movie *movie = [self parseMovieFromDictionary:dict];
            [movies addObject:movie];
        }
        
        [self.delegate receivedMovies:movies forPage:page.integerValue];
    }];
}

- (void)lookupMovieWithId:(NSNumber *)movieId {
    NSAssert(self.apiKey != nil, @"An API_KEY is required to use the movie DB. Please register a key as described");

    if ( self.movieCache[movieId] != nil ) {
        // lookup in the cache and return
        [self.delegate receivedMovieDetails:self.movieCache[movieId]];
        return;
    }
    
    NSString *urlAsString = [NSString stringWithFormat:@"http://api.themoviedb.org/3/movie/%i?api_key=%@", movieId.intValue, self.apiKey];
    NSURL *url = [[NSURL alloc] initWithString:urlAsString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:self.queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error || data == nil) {
            [self.delegate requestFailedWithError:error];
            return;
        }
        
        // Parse the raw JSON into Objects
        NSDictionary *parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if ( error ) {
            [self.delegate requestFailedWithError:error];
            return;
        }
        
        // Add the movie to the cache to avoid excessive network requests
        Movie *movie = [self parseMovieFromDictionary:parsed];
        self.movieCache[movie.id] = movie;
        [self.delegate receivedMovieDetails:movie];
    }];
}

#pragma mark - Private Helpers

/**
 *  Using Key Value Coding (KVC), iterate the JSON response object and construct a Movie using the applicable values.
 */
- (Movie *)parseMovieFromDictionary:(NSDictionary *)dict {
    Movie *movie = [Movie new];
    for ( NSString *key in dict ) {
        if ( [movie respondsToSelector:NSSelectorFromString(key)] ) {
            [movie setValue:dict[key] forKey:key];
        }
    }
    return movie;
}

/**
 * Need to make sure we are properly encoding the query for the API
 */
- (NSString *)urlEncodeQuery:(NSString *)query {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                               (CFStringRef)query,
                                                               NULL,
                                                               (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                               CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
}

@end
