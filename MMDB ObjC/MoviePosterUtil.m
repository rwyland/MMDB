//
//  MoviePosterUtil.m
//  MMDB
//
//  Created by Rob Wyland on 8/16/15.
//  Copyright (c) 2015 Org Inc. All rights reserved.
//

#import "MoviePosterUtil.h"
#import "Movie.h"

#define kSIZE  @[@"w92", @"w154"]
#define kIMG_URL @"http://image.tmdb.org/t/p/"

/**
 *  Enum the possible values supported
 *  Currently just a thumbnail and normal size
 */
typedef enum {
    ThumbnailSize = 0,
    NormalSize
} PosterImageSize;

@implementation MoviePosterUtil

+ (void)loadThumbnailPosterForMovie:(Movie *)movie intoView:(UIImageView *)imageView {
    if ( movie.poster_path == nil || [movie.poster_path isEqual:[NSNull null]] ) {
        // Sometimes there is no poster, so use placeholder
        [imageView setImage:[UIImage imageNamed:@"placeholder-w92.jpg"]];
        return;
    }
    
    UIImage *image = nil;
    if ( (image = [self lookupImageInTmpWithSize:ThumbnailSize Filename:movie.poster_path]) ) {
        // Found a cached value, use it
        [imageView setImage:image];
        return;
    }
    // Start as the placeholder
    [imageView setImage:[UIImage imageNamed:@"placeholder-w92.jpg"]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSURL *url = [self downloadUrlForImageWithSize:ThumbnailSize filename:movie.poster_path];
        NSData *imageData = [[NSData alloc] initWithContentsOfURL:url];
        if ( imageData ) {
            [self updateView:imageView withImage:[UIImage imageWithData:imageData]];
            [self saveInTmpWithFile:imageData withSize:ThumbnailSize filename:movie.poster_path];
        }
    });
}

+ (void)loadPosterForMovie:(Movie *)movie intoView:(UIImageView *)imageView {
    if ( movie.poster_path == nil || [movie.poster_path isEqual:[NSNull null]] ) {
        // Sometimes there is no poster, so use placeholder
        [imageView setImage:[UIImage imageNamed:@"placeholder-w154.jpg"]];
        return;
    }
    
    UIImage *image = nil;
    if ( (image = [self lookupImageInTmpWithSize:NormalSize Filename:movie.poster_path]) ) {
        // Found a cached value, use it
        [imageView setImage:image];
        return;
    } else if ( (image = [self lookupImageInTmpWithSize:ThumbnailSize Filename:movie.poster_path]) ) {
        // Start as the thumbnail
        [imageView setImage:image];
    } else {
        // Start as the placeholder
        [imageView setImage:[UIImage imageNamed:@"placeholder-w154.jpg"]];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSURL *url = [self downloadUrlForImageWithSize:NormalSize filename:movie.poster_path];
        NSData *imageData = [[NSData alloc] initWithContentsOfURL:url];
        if ( imageData ) {
            [self updateView:imageView withImage:[UIImage imageWithData:imageData]];
            [self saveInTmpWithFile:imageData withSize:NormalSize filename:movie.poster_path];
        }
    });
}

#pragma mark - Private Helper

/**
 *  Construct the url to request the resource
 */
+ (NSURL *)downloadUrlForImageWithSize:(PosterImageSize)imageSize filename:(NSString *)filename {
    // Construct the URL
    NSURL *url = [[NSURL alloc] initWithString:kIMG_URL];
    NSURL *sizeUrl = [url URLByAppendingPathComponent:kSIZE[imageSize]];
    NSURL *file = [sizeUrl URLByAppendingPathComponent:filename];

    return file;
}

/**
 *  Always update the View on the main thread
 *  Do a simple fade animation, this could always be nicer if need be
 */
+ (void)updateView:(UIImageView *)imageView withImage:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        [imageView setAlpha:0.f];
        [UIView animateWithDuration:0.25f animations:^{
            [imageView setImage:image];
            [imageView setAlpha:1.f];
        } completion:nil];
    });
}

/**
 *  Save the file contents into the tmp directory
 */
+ (void)saveInTmpWithFile:(NSData *)data withSize:(PosterImageSize)imageSize filename:(NSString *)filename {
    // Construct the filepath and append the size type
    NSString *tmpPath = NSTemporaryDirectory();
    NSString *filePath = [tmpPath stringByAppendingPathComponent:filename];
    NSString *file = [filePath stringByAppendingString:kSIZE[imageSize]];
    
    // Save file to tmp
    [data writeToFile:file atomically:YES];
}

/**
 *  Lookup an image in the tmp directory, and return it if it exists
 */
+ (UIImage *)lookupImageInTmpWithSize:(PosterImageSize)imageSize Filename:(NSString *)filename {
    // Construct the filepath and append the size type
    NSString *tmpPath = NSTemporaryDirectory();
    NSString *filePath = [tmpPath stringByAppendingPathComponent:filename];
    NSString *file = [filePath stringByAppendingString:kSIZE[imageSize]];
    
    NSError *error = nil;
    NSData *imageData = [NSData dataWithContentsOfFile:file options:0 error:&error];
    if ( error == nil ) {
        // Image found, return it
        return [UIImage imageWithData:imageData];
    }

    // Nothing found
    return nil;
}

@end
