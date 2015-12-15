//
//  MoviePosterUtil.swift
//  MMDB Swift
//
//  Created by Rob W on 12/11/15.
//  Copyright © 2015 Org Inc. All rights reserved.
//

import UIKit

let kSIZE: Array<String> = ["w92", "w154"]
let kIMG_URL: String = "http://image.tmdb.org/t/p/"

enum PosterImageSize: Int {
  case Thumbnail = 0, Normal
}

class MoviePosterUtil {
  
  /**
   *  Lookup the poster resource in size w92 and load into the imageView.
   *  Cache the values in the tmp directory in the app sandbox.
   */
  static func loadThumbnailPosterForMovie(movie: Movie, intoView imageView: UIImageView) {
    if let _ = movie.poster_path {
      if let cached = self.lookupImageInTmpWithSize(.Thumbnail, filename: movie.poster_path!) {
        // Found a cached value, use it
        imageView.image = cached
        return
      }
      
      // Start as the placeholder
      imageView.image = UIImage(imageLiteral: "placeholder-w92.jpg")
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
        let url: NSURL = downloadUrlForImageWithSize(.Thumbnail, filename: movie.poster_path!)
        if let imageData = NSData(contentsOfURL: url), image = UIImage(data: imageData) {
          updateView(imageView, withImage: image)
          saveInTmpWithFile(imageData, withSize: .Thumbnail, filename: movie.poster_path!)
        }
      })
    } else {
      // Sometimes there is no poster, so use placeholder
      imageView.image = UIImage(imageLiteral: "placeholder-w92.jpg")
    }
  }
  
  /**
   *  Lookup the poster resource in size w154 and load into the view.
   *  Temporarily stretch and use the w92 thumbnail (if available) while downloading the w154.
   *  Cache the values in the tmp directory in the app sandbox.
   */
  static func loadPosterForMovie(movie: Movie, intoView imageView: UIImageView) {
    if let _ = movie.poster_path {
      if let cached = self.lookupImageInTmpWithSize(.Normal, filename: movie.poster_path!) {
        // Found a cached value, use it
        imageView.image = cached
        return
      } else if let cached = self.lookupImageInTmpWithSize(.Thumbnail, filename: movie.poster_path!) {
        // Start as the thumbnail
        imageView.image = cached
      } else {
        // Start as the placeholder
        imageView.image = UIImage(imageLiteral: "placeholder-w154.jpg")
      }
      
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
        let url: NSURL = downloadUrlForImageWithSize(.Normal, filename: movie.poster_path!)
        if let imageData = NSData(contentsOfURL: url), image = UIImage(data: imageData) {
          updateView(imageView, withImage: image)
          saveInTmpWithFile(imageData, withSize: .Normal, filename: movie.poster_path!)
        }
      })
    } else {
      // Sometimes there is no poster, so use placeholder
      imageView.image = UIImage(imageLiteral: "placeholder-w154.jpg")
    }
  }

  // MARK: - Private Helper

  /**
   *  Construct the url to request the resource
   */
  static private func downloadUrlForImageWithSize(imageSize: PosterImageSize, filename: String) -> NSURL {
    // Construct the URL
    let url = NSURL(string: kIMG_URL)!
    let sizeUrl = url.URLByAppendingPathComponent(kSIZE[imageSize.rawValue])
    let file = sizeUrl.URLByAppendingPathComponent(filename)
    return file;
  }
  
  /**
   *  Always update the View on the main thread
   *  Do a simple fade animation, this could always be nicer if need be
   */
  static private func updateView(imageView: UIImageView, withImage image: UIImage ) {
    dispatch_async(dispatch_get_main_queue(), {
      imageView.alpha = 0
      UIView.animateWithDuration(0.25, animations: {
        imageView.image = image
        imageView.alpha = 1
      }, completion: nil)
    })
  }
  
  /**
   *  Save the file contents into the tmp directory
   */
  static private func saveInTmpWithFile(data: NSData, withSize imageSize: PosterImageSize, filename: String ) {
    // Construct the filepath and append the size type
    let tmpPath: String = NSTemporaryDirectory()
    let filePath: String = tmpPath + "/" + filename
    let file: String = filePath + kSIZE[imageSize.rawValue]
  
    // Save file to tmp
    data.writeToFile(file, atomically: true)
  }
  
  /**
   *  Lookup an image in the tmp directory, and return it if it exists
   */
  static private func lookupImageInTmpWithSize(imageSize: PosterImageSize, filename: String) -> UIImage? {
    let tmpPath: String = NSTemporaryDirectory()
    let filePath: String = tmpPath + "/" + filename
    let file: String = filePath + kSIZE[imageSize.rawValue]
   
    do {
      let image = try NSData(contentsOfFile: file, options: .DataReadingMappedIfSafe)
      return UIImage(data: image)
    } catch {
      return nil
    }
  }
}