//
//  MovieListViewController.swift
//  MMDB Swift
//
//  Created by Rob W on 12/11/15.
//  Copyright © 2015 Org Inc. All rights reserved.
//

import UIKit

let kHOT_TITLE: String = "What's Hot!"
let kSEARCH_TITLE: String = "Search"

class MovieListViewController: UIViewController {
  
  var tableView: UITableView = UITableView(frame: .zero, style: .Plain)
  var moviesDatasource: Array<Movie> = []
  
  let movieDBService: MovieDBService = MovieDBService()
  
  let searchBar: UISearchBar = UISearchBar(frame: CGRectMake(0, 0, 200, 40))
  var query: String? = nil
  var isSearching: Bool = false
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.addSubview(tableView)
    self.tableView.frame = self.view.bounds
    self.tableView.delegate = self
    self.tableView.dataSource = self
    
    self.movieDBService.delegate = self
    self.movieDBService.requestPopularMoviesWithPage(1)
    
    self.navigationItem.title = kHOT_TITLE
    let search = UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: Selector("onSearch:"))
    self.navigationItem.rightBarButtonItem = search
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
   
    self.tableView.reloadData()
  }
  
  // MARK: - Controller Actions
  
  func onSearch(sender: AnyObject?) {
    // Swap search with a cancel button
    let cancel: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: Selector("onCancel:"))
    self.navigationItem.setRightBarButtonItem(cancel, animated: true)
    
    // This could also have an animation
    self.navigationItem.title = kSEARCH_TITLE
    self.navigationItem.titleView = self.searchBar
    self.searchBar.delegate = self
    self.searchBar.becomeFirstResponder()
  }
  
  func onCancel(sender: AnyObject?) {
    // Swap cancel with a search button
    let search: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: Selector("onSearch:"))
    self.navigationItem.setRightBarButtonItem(search, animated: true)
    
  
    // This could also have an animation
    self.navigationItem.title = kHOT_TITLE
    self.navigationItem.titleView = nil
    self.searchBar.delegate = nil
  
    // Switch back to the popular results
    self.isSearching = false
    self.query = nil
    self.movieDBService.requestPopularMoviesWithPage(1)
  }
}

// MARK: - Table Delegate and Datasource protocol

extension MovieListViewController: UITableViewDelegate {
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 150
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
    
    // TODO: This request can appear to "hang" if the network is slow or even offline. Ideally we want to provide feedback
    let movie: Movie = self.moviesDatasource[indexPath.row]
    self.movieDBService.lookupMovieWithId(movie.id)
  }
  
  func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
    let movie: Movie = self.moviesDatasource[indexPath.row]
    cell.textLabel!.text = movie.title
    cell.detailTextLabel!.text = movie.year()
    MoviePosterUtil.loadThumbnailPosterForMovie(movie, intoView:cell.imageView!)
    
    if indexPath.row >= self.moviesDatasource.count - 1 {
      let nextPage = (self.moviesDatasource.count / 20) + 1
      
      // TODO: This request can appear to "hang" if the network is slow or even offline. Ideally we want to provide feedback
      self.isSearching ? self.movieDBService.searchMoviesWithQuery(self.query!, andPage:nextPage) : self.movieDBService.requestPopularMoviesWithPage(nextPage)
    }
  }
}

extension MovieListViewController: UITableViewDataSource {
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.moviesDatasource.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    // Using a simple layout with some slight modifications.
    // This could always use a subclass of UITableCell to use a custom design with more info like movie rating or vote rating
    let cellIdentifier = "MovieCell"
    guard let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) else {
      let newCell = UITableViewCell(style: .Subtitle, reuseIdentifier: cellIdentifier)
      newCell.textLabel!.font = UIFont.systemFontOfSize(24)
      newCell.textLabel!.numberOfLines = 3
      newCell.detailTextLabel!.font = UIFont.systemFontOfSize(18)
      newCell.detailTextLabel!.textColor = UIColor(white: 0.35, alpha: 1)
      newCell.accessoryType = .DisclosureIndicator
      return newCell
    }
    return cell
  }
}

// MARK: - Search Bar Delegate

extension MovieListViewController: UISearchBarDelegate {
  func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
    // Add a grey effect and don't allow scrolling, this could also be done with an animation
    self.tableView.alpha = 0.5
    self.tableView.userInteractionEnabled = false
  }
  
  func searchBarTextDidEndEditing(searchBar: UISearchBar) {
    // remove grey effect and allow scrolling, this could also be done with an animation
    self.tableView.alpha = 1
    self.tableView.userInteractionEnabled = true
  }
  
  func searchBarSearchButtonClicked(searchBar: UISearchBar) {
    if let text = searchBar.text where text.characters.count > 0 {
      searchBarTextDidEndEditing(searchBar)
      self.isSearching = true
      self.query = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
      self.movieDBService.searchMoviesWithQuery(self.query!, andPage: 1)
    }
  }
}

// MARK: - Movie Lookup Delegate

extension MovieListViewController: MovieLookupDelegate {
  func receivedMovies(movies: Array<Movie>, forPage page: Int) {
    if movies.count == 0 && page == 1 {
      // The contents are empty, provide feedback to the user
      // We probably dont want to be annoying with an alert, so something like using the table footer would also work
      dispatch_async(dispatch_get_main_queue(), {
        let alertVC: UIAlertController = UIAlertController(title: "No Results", message: "please try again", preferredStyle: .Alert)
        let action: UIAlertAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertVC.addAction(action)
        self.presentViewController(alertVC, animated: true, completion: nil)
      })
      return
    } else if movies.count == 0 {
      // Empty page, nothing new to show so do nothing
      return
    } else if page == 1 {
      // Start over, new request!
      self.moviesDatasource.removeAll()
    }
    self.moviesDatasource.appendContentsOf(movies)
    
    // Always reload the view on the main thread
    dispatch_async(dispatch_get_main_queue(), {
      self.tableView.reloadData()
    })
  }
  
  func receivedMovieDetails(movie: Movie) {
    // Always make changes to the view heiarchy on the main thread
    dispatch_async(dispatch_get_main_queue(), {
      let detailsVC: MovieDetailsViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("MovieDetailsViewController") as! MovieDetailsViewController
      detailsVC.movie = movie
      self.navigationController?.pushViewController(detailsVC, animated: true)
    })
  }
  
  func requestFailedWithError(error: NSError) {
    // An error happened, let the user know!
    // Ideally we would want user friendly messages, with some sort of next-step for the user to try
    dispatch_async(dispatch_get_main_queue(), {
      let alertVC: UIAlertController = UIAlertController(title: "Network Fail", message: error.description, preferredStyle: .Alert)
      let action: UIAlertAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
      alertVC.addAction(action)
      self.presentViewController(alertVC, animated: true, completion: nil)
    })
  }
}