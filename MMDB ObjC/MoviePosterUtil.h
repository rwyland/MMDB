//
//  MoviePosterUtil.h
//  MMDB
//
//  Created by Rob Wyland on 8/16/15.
//  Copyright (c) 2015 Org Inc. All rights reserved.
//

@class Movie;

/**
 *  A Utility used to display poster images by downloading and caching resources.
 */
@interface MoviePosterUtil : NSObject

/**
 *  Lookup the poster resource in size w92 and load into the imageView.
 *  Cache the values in the tmp directory in the app sandbox.
 */
+ (void)loadThumbnailPosterForMovie:(Movie *)movie intoView:(UIImageView *)imageView;

/**
 *  Lookup the poster resource in size w154 and load into the view.
 *  Temporarily stretch and use the w92 thumbnail (if available) while downloading the w154.
 *  Cache the values in the tmp directory in the app sandbox.
 */
+ (void)loadPosterForMovie:(Movie *)movie intoView:(UIImageView *)imageView;

@end
