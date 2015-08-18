# MMDB
My Movie Database - iOS Demo App

### Movie Database API
This is a sample project that uses the [Movie Database API](http://docs.themoviedb.apiary.io/) by Travis Bell.

The app will need an API key generated in order to build and run correctly. To [register for an API key](https://www.themoviedb.org/login), head into your account page on TMDb and generate a new key from within the "API" section found in the left hand sidebar.

Once you have an API key, you will need to add a new properties list file called `apiKey.plist` with a single string entry with key `kAPI_KEY` and value set to your API key. This secret file is ignored by git.

Run the app and you should be good to go!

### The App
This app uses several core principles of iOS app and obj-c development:
* Native development using CocoaTouch and UIKit frameworks
* Use of Model-View-Controller (MVC) architectural pattern
* Protocols and delegates to decouple objects
* Key Value Coding (KVC)
* Concurrent processes using blocks and Grand Central Dispatch (GCD)
* Network requests and responses to a RESTful JSON API
* Filesystem storage of cached resources in the app sandbox
* Use of Quartz for drawing into a view
* Examples of both Autolayout and Autosizing in Interface Builder 
* An example Asset resource to support differing screen densities
* A sample test suite for testing the stability of the APIs
