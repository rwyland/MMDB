//
//  Movie.swift
//  MMDB Swift
//
//  Created by Rob W on 12/11/15.
//  Copyright © 2015 Org Inc. All rights reserved.
//

import UIKit

class Movie: NSObject {
  
  dynamic var id: Int = 0
  dynamic var title: String?
  dynamic var poster_path: String?
  dynamic var release_date: String?
  dynamic var runtime: Int = 0
  dynamic var overview: String = "No Description Available"
  dynamic var vote_average: Double = 0.0
  dynamic var vote_count: Int = 0
  
  func year() -> String? {
    if let date = self.release_date where date.characters.count > 4 {
      return "(\(date.substringToIndex(date.startIndex.advancedBy(4))))"
    }
    return nil
  }
  
  func duration() -> String? {
    //if let time = self.runtime {
      return "\(self.runtime / 60)hr \(self.runtime % 60)min"
    //}
    //return nil
  }
  
  func rating() -> String? {
    //if let average = self.vote_average where self.vote_average > 0 {
      return String(format: "%.1f", self.vote_average)
    //}
    //return nil
  }
  
  override func doesNotRecognizeSelector(aSelector: Selector) {
    print("Do not know selector: \(aSelector)")
    // do nothing to avoid raising exceptions during KVO
  }
}