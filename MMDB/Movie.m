//
//  Movie.m
//  MMDB
//
//  Created by Rob Wyland on 8/13/15.
//  Copyright (c) 2015 Org Inc. All rights reserved.
//

#import "Movie.h"

@implementation Movie

- (NSString *)overview {
    return _overview != nil && ![_overview isEqual:[NSNull null]] ? _overview : @"No Description Available";
}

- (NSString *)year {
    // Just do a quick substring since year will always be the first four chars
    return self.release_date != nil && ![self.release_date isEqual:[NSNull null]] && self.release_date.length ? [NSString stringWithFormat:@"(%@)", [self.release_date substringToIndex:4]] : nil;
}

- (NSString *)duration {
    // Do some quick calculations to determine hours and minutes
    return self.runtime != nil && ![self.runtime isEqual:[NSNull null]] ? [NSString stringWithFormat:@"%ihr %imin", (self.runtime.intValue / 60), (self.runtime.intValue % 60)] : nil;
}

- (NSString *)rating {
    // Write out the rating with a single decimal point
    return self.vote_average != nil && ![self.vote_average isEqual:[NSNull null]] ? [NSString stringWithFormat:@"%.1f", self.vote_average.floatValue] : @"";
}

@end
