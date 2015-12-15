//
//  MMDBTests.m
//  MMDBTests
//
//  Created by Rob Wyland on 8/13/15.
//  Copyright (c) 2015 Org Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <CommonCrypto/CommonDigest.h>

#import "Movie.h"
#import "MovieDBService.h"
#import "MoviePosterUtil.h"

@interface MMDBTests : XCTestCase <MovieLookupDelegate>

@property (strong, nonatomic) MovieDBService *dbService;
@property (strong, nonatomic) XCTestExpectation *responseExpectation;

@end


/**
 *  This test suite just runs some basic tests against the Movie DB APIs to make sure everything is operating as expected.
 *  Possible failures can occur from API_KEY errors, server side issues, network connectivity problems, and changes to the API.
 *  As a starting point, these tests are for basic assumptions, so further testing would be needed.
 *  Possible areas of expanded testing: 
 *    Further testing of the poster/thumbnail cache to make sure extra networks calls are not made
 *    Testing of the List view to ensure cells are properly being setup and paging
 *    Testing of the Details view to ensure all details are correctly loaded into the View from the Model
 *    Testing of the Movie Details cache, to ensure the cache is properly used
 *    Forced testing of error cases like invalid API calls, using empty Movie objects with empty variables, network offline
 */
@implementation MMDBTests

- (void)setUp {
    [super setUp];

    self.dbService = [[MovieDBService alloc] init];
    self.dbService.delegate = self;
    [self emptyTmpDirectory];
}

- (void)tearDown {
    self.dbService.delegate = nil;

    [super tearDown];
}

#pragma mark - DB Service Delegate

- (void)receivedMovies:(NSArray *)movies forPage:(NSUInteger)page {
    XCTAssertNotNil(movies, @"movies object returned in response is nil");
    XCTAssertEqual(movies.count, 20);
    XCTAssertEqual(page, 1);
    [self.responseExpectation fulfill];
}

- (void)receivedMovieDetails:(Movie *)movie {
    XCTAssertNotNil(movie, @"movie returned in response is nil");
    XCTAssertEqualObjects(movie.id, @11);
    XCTAssertEqualObjects(movie.title, @"Star Wars");
    XCTAssertEqualObjects(movie.poster_path, @"/tvSlBzAdRE29bZe5yYWrJ2ds137.jpg");
    XCTAssertEqualObjects(movie.release_date, @"1977-05-25");
    XCTAssertEqualObjects(movie.runtime, @121);
    XCTAssertTrue([movie.overview hasPrefix:@"Princess Leia is captured and held hostage by the evil Imperial forces in their effort to tak"]);
    XCTAssertEqualObjects(movie.year, @"(1977)");
    XCTAssertEqualObjects(movie.duration, @"2hr 1min");
    XCTAssertGreaterThanOrEqual(movie.vote_count.floatValue, 0.f);
    XCTAssertGreaterThanOrEqual(movie.vote_average.floatValue, 0.f);
    XCTAssertLessThanOrEqual(movie.vote_average.floatValue, 10.f);
    
    [self.responseExpectation fulfill];
}

- (void)requestFailedWithError:(NSError *)error {
    XCTFail(@"%@", error.description);
}


#pragma mark - Test Cases

/**
 *  Test the popular movie API
 */
- (void)testPopular {
    self.responseExpectation = [self expectationWithDescription:@"response from popular API"];
    [self.dbService requestPopularMoviesWithPage:1];
    [self waitForExpectationsWithTimeout:2.f handler:^(NSError *error) {
        if ( error ) {
            NSLog(@"Timeout Error: %@", error);
            XCTFail(@"%@", error.description);
        }
    }];
    XCTAssert(YES, @"Pass");
}

/**
 *  Test the search movie API
 */
- (void)testSearch {
    self.responseExpectation = [self expectationWithDescription:@"response from popular API"];
    [self.dbService searchMoviesWithQuery:@"Star Wars" andPage:1];
    [self waitForExpectationsWithTimeout:2.f handler:^(NSError *error) {
        if ( error ) {
            NSLog(@"Timeout Error: %@", error);
            XCTFail(@"%@", error.description);
        }
    }];
    XCTAssert(YES, @"Pass");
}

/**
 * Test the movie API by id
 */
- (void)testMovieDetails {
    self.responseExpectation = [self expectationWithDescription:@"response from popular API"];
    [self.dbService lookupMovieWithId:@11];
    [self waitForExpectationsWithTimeout:2.f handler:^(NSError *error) {
        if ( error ) {
            NSLog(@"Timeout Error: %@", error);
            XCTFail(@"%@", error.description);
        }
    }];
    XCTAssert(YES, @"Pass");
}

/**
 *  Test the poster thumbnail API and cache
 */
- (void)testThumbnailCache {
    Movie *movie = [Movie new];
    [movie setPoster_path:@"/tvSlBzAdRE29bZe5yYWrJ2ds137.jpg"];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, 92.f, 138.f)];
    XCTAssertNil(imageView.image);
    
    // First load will go from nil, to grey, to thumbnail
    self.responseExpectation = [self keyValueObservingExpectationForObject:imageView keyPath:@"image" handler:^BOOL(id observedObject, NSDictionary *change) {
        XCTAssertNotNil(observedObject, @"imageView returned is nil");
        XCTAssertEqualObjects(change[@"old"], [NSNull null]);
        XCTAssertNotNil(change[@"new"], @"image returned is nil");
        NSString *hashNew = [self checksum:change[@"new"]];
        XCTAssertNotNil(hashNew, @"image returned is nil");
        return YES;
    }];
    [MoviePosterUtil loadThumbnailPosterForMovie:movie intoView:imageView];

    [self waitForExpectationsWithTimeout:2.f handler:^(NSError *error) {
        if ( error ) {
            NSLog(@"Timeout Error: %@", error);
            XCTFail(@"%@", error.description);
        }
        XCTAssertNotNil(imageView.image);
        
        // Second load will just reuse the thumbnail, so its the same
        self.responseExpectation = [self keyValueObservingExpectationForObject:imageView keyPath:@"image" handler:^BOOL(id observedObject, NSDictionary *change) {
            XCTAssertNotNil(observedObject, @"imageView returned is nil");
            XCTAssertNotNil(change[@"old"], @"image returned is nil");
            XCTAssertNotNil(change[@"new"], @"image returned is nil");
            NSString *hashOld = [self checksum:change[@"old"]];
            NSString *hashNew = [self checksum:change[@"new"]];
            XCTAssertEqualObjects(hashOld, hashNew);
            return YES;
        }];
        [MoviePosterUtil loadThumbnailPosterForMovie:movie intoView:imageView];
        [self waitForExpectationsWithTimeout:2.f handler:^(NSError *error) {
            if ( error ) {
                NSLog(@"Timeout Error: %@", error);
                XCTFail(@"%@", error.description);
            }
        }];
    }];
    XCTAssert(YES, @"Pass");
}

/**
 *  Test the poster API and cache
 */
- (void)testPosterCache {
    Movie *movie = [Movie new];
    [movie setPoster_path:@"/tvSlBzAdRE29bZe5yYWrJ2ds137.jpg"];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, 154.f, 231.f)];
    XCTAssertNil(imageView.image);
    
    // First load will go from nil, to grey, to poster
    self.responseExpectation = [self keyValueObservingExpectationForObject:imageView keyPath:@"image" handler:^BOOL(id observedObject, NSDictionary *change) {
        XCTAssertNotNil(observedObject, @"imageView returned is nil");
        XCTAssertEqualObjects(change[@"old"], [NSNull null]);
        XCTAssertNotNil(change[@"new"], @"image returned is nil");
        NSString *hashNew = [self checksum:change[@"new"]];
        XCTAssertNotNil(hashNew, @"image returned is nil");
        return YES;
    }];
    [MoviePosterUtil loadPosterForMovie:movie intoView:imageView];
    [self waitForExpectationsWithTimeout:2.f handler:^(NSError *error) {
        if ( error ) {
            NSLog(@"Timeout Error: %@", error);
            XCTFail(@"%@", error.description);
        }
        XCTAssertNotNil(imageView.image);
        
        // Second load will just reuse the poster, so its the same
        self.responseExpectation = [self keyValueObservingExpectationForObject:imageView keyPath:@"image" handler:^BOOL(id observedObject, NSDictionary *change) {
            XCTAssertNotNil(observedObject, @"imageView returned is nil");
            XCTAssertNotNil(change[@"old"], @"image returned is nil");
            XCTAssertNotNil(change[@"new"], @"image returned is nil");
            NSString *hashOld = [self checksum:change[@"old"]];
            NSString *hashNew = [self checksum:change[@"new"]];
            XCTAssertEqualObjects(hashOld, hashNew);
            return YES;
        }];
        [MoviePosterUtil loadPosterForMovie:movie intoView:imageView];
        [self waitForExpectationsWithTimeout:2.f handler:^(NSError *error) {
            if ( error ) {
                NSLog(@"Timeout Error: %@", error);
                XCTFail(@"%@", error.description);
            }
        }];
    }];
    XCTAssert(YES, @"Pass");
}

#pragma mark - Private Helpers

- (NSString *)checksum:(UIImage *)image {
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(image)];
    CC_MD5([imageData bytes], (CC_LONG)[imageData length], result);
    NSString *imageHash = [NSString stringWithFormat:
                           @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                           result[0], result[1], result[2], result[3],
                           result[4], result[5], result[6], result[7],
                           result[8], result[9], result[10], result[11],
                           result[12], result[13], result[14], result[15]
                           ];
    return imageHash;
}

- (void)emptyTmpDirectory {
    NSArray *tmpDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
    for (NSString *file in tmpDirectory) {
        [[NSFileManager defaultManager] removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:file] error:NULL];
    }
}

@end
