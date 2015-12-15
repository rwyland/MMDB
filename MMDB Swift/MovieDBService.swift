//
//  MovieDBService.swift
//  MMDB Swift
//
//  Created by Rob W on 12/11/15.
//  Copyright © 2015 Org Inc. All rights reserved.
//

import UIKit

protocol MovieLookupDelegate {
  /** A Delegate to receive responses for async network calls. */
  func receivedMovies(movies: Array<Movie>, forPage page: Int)
  
  /** A movie returned for a specific lookup on id. This will cache movies for quicker responsiveness. */
  func receivedMovieDetails(movie: Movie)
  
  /** Some sort of failure from the network call. */
  func requestFailedWithError(error: NSError)
}

class MovieDBService {
  
  /** A queue to support network calls on a background thread */
  let queue: NSOperationQueue = NSOperationQueue()
  
  /**
   *  A simple cache by movie id.
   *  All of the contents of a movie are historical, however the user rating and voting can change, so ideally we would support updating the cache.
   *  We could accomplish this by immediately returning the cache value, and then applying an update to the View if the cache was found to be stale.
   */
  var movieCache: Dictionary<Int, Movie> = [:]
  
  /**
   *  This is loaded from a local plist called "apiKey.plist" with a single string entry:
   *  { @"kAPI_KEY" : @"Your API key" }
   */
  var apiKey: String?
  
  var delegate: protocol<MovieLookupDelegate>?
  
  // MARK: - Init
  
  init() {
    // Find out the path of the local api key properties list
    let path = NSBundle.mainBundle().pathForResource("apiKey", ofType: "plist")
    if let dict = NSDictionary(contentsOfFile: path!) {
      self.apiKey = dict["kAPI_KEY"] as? String
    }
  }
  
  func requestPopularMoviesWithPage(page: Int) {
    assert(self.apiKey != nil, "An API_KEY is required to use the movie DB. Please register a key as described")
    
    if page > 1000 {
      // The API doesn't support anything over 1000
      self.delegate?.requestFailedWithError(NSError(domain: "Invalid page number", code: 400, userInfo: nil))
      return
    }
    
    let urlString = "http://api.themoviedb.org/3/movie/popular?api_key=\(self.apiKey!)&page=\(page)"
    let url = NSURL(string: urlString)!
    let task = NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data, response, error) in
      if let error = error where data == nil {
        self.delegate?.requestFailedWithError(error)
        return
      }
      
      // Parse the raw JSON into Objects
      do {
        let parsed = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as! Dictionary<String, AnyObject>
        let page = parsed["page"]! as! Int
        // These can be useful for displaying in the View
        //let totalPages = parsed["total_pages"] as! Int
        //let totalResults = parsed["total_results"] as! Int
        var movies: Array<Movie> = []
        let results = parsed["results"] as! Array<AnyObject>
        for value in results {
          let movie = self.parseMovieFromDictionary(value as! Dictionary<String, AnyObject>)
          movies.append(movie)
        }
        self.delegate?.receivedMovies(movies, forPage: page)
      } catch {
        self.delegate?.requestFailedWithError(NSError(domain: "JSON Parse Error", code: 400, userInfo: nil))
        return
      }
    })
    task.resume()
  }
  
  func searchMoviesWithQuery(query: String, andPage page: Int) {
    assert(self.apiKey != nil, "An API_KEY is required to use the movie DB. Please register a key as described")

    if page > 1000 {
      // The API doesn't support anything over 1000
      self.delegate?.requestFailedWithError(NSError(domain: "Invalid page number", code: 400, userInfo: nil))
      return
    }
    
    let encoded = self.urlEncodeQuery(query)
    let urlString = "http://api.themoviedb.org/3/search/movie?api_key=\(self.apiKey!)&query=\(encoded)&page=\(page)"
    let url = NSURL(string: urlString)!
    let task = NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data, response, error) in
      if let error = error where data == nil {
        self.delegate?.requestFailedWithError(error)
        return
      }
      
      // Parse the raw JSON into Objects
      do {
        let parsed = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as! Dictionary<String, AnyObject>
        let page = parsed["page"]! as! Int
        // These can be useful for displaying in the View
        //let totalPages = parsed["total_pages"] as! Int
        //let totalResults = parsed["total_results"] as! Int
        var movies: Array<Movie> = []
        let results = parsed["results"] as! Array<AnyObject>
        for value in results {
          let movie = self.parseMovieFromDictionary(value as! Dictionary<String, AnyObject>)
          movies.append(movie)
        }
        self.delegate?.receivedMovies(movies, forPage: page)
      } catch {
        self.delegate?.requestFailedWithError(NSError(domain: "JSON Parse Error", code: 400, userInfo: nil))
        return
      }
    })
    task.resume()
  }
  
  func lookupMovieWithId(movieId: Int ) {
    assert(self.apiKey != nil, "An API_KEY is required to use the movie DB. Please register a key as described")

    if let movie = self.movieCache[movieId] {
      // lookup in the cache and return
      self.delegate?.receivedMovieDetails( movie )
      return
    }
    
    let urlString = "http://api.themoviedb.org/3/movie/\(movieId)?api_key=\(self.apiKey!)"
    let url = NSURL(string: urlString)!
    let task = NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data, response, error) in
      if let error = error where data == nil {
        self.delegate?.requestFailedWithError(error)
        return
      }
      
      // Parse the raw JSON into Objects
      do {
        let parsed = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as! Dictionary<String, AnyObject>
        let movie = self.parseMovieFromDictionary(parsed)
        
        // Add the movie to the cache to avoid excessive network requests
        self.movieCache[movie.id] = movie
        self.delegate?.receivedMovieDetails(movie)
      } catch {
        self.delegate?.requestFailedWithError(NSError(domain: "JSON Parse Error", code: 400, userInfo: nil))
        return
      }
    })
    task.resume()
  }
  
  // MARK: - Private Helpers
  
  /** Using Key Value Coding (KVC), iterate the JSON response object and construct a Movie using the applicable values */
  private func parseMovieFromDictionary(dict: Dictionary<String, AnyObject>) -> Movie {
    let movie = Movie()
    for (key, value) in dict {
      if value !== NSNull() && movie.respondsToSelector(Selector(key)) {
        movie.setValue(value, forKey: key)
      }
    }
    return movie
  }
  
  /** Need to make sure we are properly encoding the query for the API */
  func urlEncodeQuery(query: String) -> String {
    return query.stringByAddingPercentEncodingWithAllowedCharacters( NSCharacterSet.URLQueryAllowedCharacterSet() )!
  }
}