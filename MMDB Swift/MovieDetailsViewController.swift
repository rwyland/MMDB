//
//  MovieDetailsViewController.swift
//  MMDB Swift
//
//  Created by Rob W on 12/11/15.
//  Copyright © 2015 Org Inc. All rights reserved.
//

import UIKit

class MovieDetailsViewController: UIViewController {
  
  var movie: Movie?
  
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var yearLabel: UILabel!
  @IBOutlet var durationLabel: UILabel!
  @IBOutlet var voteCountLabel: UILabel!
  
  @IBOutlet var imageView: UIImageView!
  @IBOutlet var starView: StarView!
  
  @IBOutlet var descriptionView: UITextView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.titleLabel?.backgroundColor = UIColor.clearColor()
    self.yearLabel?.backgroundColor = UIColor.clearColor()
    self.durationLabel?.backgroundColor = UIColor.clearColor()
    self.voteCountLabel?.backgroundColor = UIColor.clearColor()
    self.imageView?.backgroundColor = UIColor.clearColor()
    self.starView?.backgroundColor = UIColor.clearColor()
    self.descriptionView?.backgroundColor = UIColor.clearColor()
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    if let movie = self.movie {
      self.titleLabel.text = movie.title
      self.yearLabel.text = movie.year()
      self.durationLabel.text = movie.duration()
      self.voteCountLabel.text = "\(movie.vote_count) votes"
      self.descriptionView.text = movie.overview
      MoviePosterUtil.loadPosterForMovie(movie, intoView:self.imageView)
      self.starView.rating = movie.rating()
    }
  }
}
