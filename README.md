# LakersFanhub
Udacity Program App5 (final)

Synopsis:

	Lakers Fanhub is a app made for fans of Los Angeles Lakers. It has a two main tabs: 
  
  	First NewsFeedTab utilized Apple's NSXMLParser Class to provide users with multiple sources of lakers/NBA news, presented as a tableView. Each table cell is populated with news title and updated time . User will be directed to the associated web page upon hit a table cell. User can switch between news sources at the drop down navigation title, where news sources are pre-setted here.

  	Second ClosestFansTab utilized Apple's MultipeerConnectivity framework to provide a short distance chat function (no celluar signal requred). Users can browser, connect and chat with each other, as long as they are whitin the connectable distance (depends on the Bluetooth or Wifi range of two devices). All connections and chat messages are stored in CoreData and can be viewed and managed at ChatHistoryTableView.

  	Other tabs are simple views, one is a daily NBA game match web page, the other is a rate app in AppStore view.


Purpose:
	
	As a laker fan, I want to creat a clean look news reader app for all laker fans, and personally I'm interested in Apple's MultipperConnectivity frameworkand, so I added the possiblity of finding and chatting with nearby fans into this app.


Installation:
	
	This app has installed and used CocoaPods, so make sure to click "Lakers Fanhub.xcworkspace" to open this project.

Framework/CocoaPods used:
	
	Apple: MultipeerConnectivity Framework
	CocoaPods: MBProgressHUD, https://github.com/jdg/MBProgressHUD
	CocoaPods: BTNavigationDropdownMenu, https://github.com/PhamBaTho/BTNavigationDropdownMenu

Requirement:
	iOS 8.0+ (CocoaPods with Swift support will only work on iOS 8.0+)
	Xcode 7.0+, Swift 2.0+

License:
	This app is distributed under the terms and conditions of the MIT license
