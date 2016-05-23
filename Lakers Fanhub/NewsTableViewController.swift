//
//  NewsViewController.swift
//  Lakers Fanhub
//
//  Created by Li Yin on 4/5/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD
import BTNavigationDropdownMenu


class NewsTableViewController: UITableViewController, XMLParserDelegate {
    
    var feedParser = XMLParser()
    var loadingHUD: MBProgressHUD!
    var menuView: BTNavigationDropdownMenu!
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var newsFeeds = [[String:String]]()
    var newsSoucreString: String!
    
    @IBInspectable var titleTextColor: UIColor = UIColor.blackColor()
    @IBInspectable var subTitleTextColor: UIColor = UIColor.blackColor()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //If view has not been fully configed due to lack of internet connection, finish the configration
        if Reachability.isConnectedToNetwork() && refreshControl == nil {
            configDropDownMenu()
            configHUDAndRefreshControl()
            startParseFeeds()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        feedParser.delegate = self
        ConvenientView.sharedInstance().setDarkNaviBar(self)
        tabBarController?.tabBar.tintColor = ConvenientData().lakersPurpleColor
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        
        //Check whether user has internet connection
        if Reachability.isConnectedToNetwork(){
            configDropDownMenu()
            configHUDAndRefreshControl()
            startParseFeeds()
        } else {
            dispatch_async(dispatch_get_main_queue()){
                ConvenientView.sharedInstance().showNoConnectionAlertView(self)
            }
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsFeeds.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("newsTableViewCell") as! NewsTableViewCell
        let feedDic = newsFeeds[indexPath.row]
        cell.cellImageView.image = UIImage(named: "TableNewsPlaceHolder")
        cell.cellTitle.text = feedDic["title"]
        cell.cellFeedPublished.text = feedDic["published"] ?? feedDic["pubDate"]
        ConvenientView.sharedInstance().setLabel(cell.cellTitle, fontName: "HelveticaNeue-Medium", size: 14, color: titleTextColor)
        ConvenientView.sharedInstance().setLabel(cell.cellFeedPublished, fontName: "HelveticaNeue-Light", size: 12, color: subTitleTextColor)
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70.0
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let feedDic = newsFeeds[indexPath.row]
        let controller = self.storyboard?.instantiateViewControllerWithIdentifier("NewsDetailViewController") as! NewsDetailViewController
        controller.feedURLString = feedDic["link"]!
        navigationController?.pushViewController(controller, animated: true)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
    }
    
    //Action fucntion for pull-down-refresh
    func refreshTable(refreshControl: UIRefreshControl){
        //Each time user refresh the tableView, check the internet connection status
        if Reachability.isConnectedToNetwork(){
            newsFeeds = [[String:String]]()
            tableView.reloadData()
            startParseFeeds()
            refreshControl.endRefreshing()
        } else {
            refreshControl.endRefreshing()
            dispatch_async(dispatch_get_main_queue()){
                ConvenientView.sharedInstance().showNoConnectionAlertView(self)
            }
        }
    }
    
    //Help function for XMLParser
    func startParseFeeds(){
        //First check whether CoreData has stored feed Dictionary, if so, load CoreData info
        
        if Reachability.isConnectedToNetwork(){
            feedParser.parsedDataArray = []
            feedParser.currentDataDic = [String:String]()
            let url = NSURL(string: ConvenientData().newsSourceDict[newsSoucreString]!)
            feedParser.parseWithURL(url!)
        } else {
            dispatch_async(dispatch_get_main_queue()){
                self.loadingHUD.hide(true)
                ConvenientView.sharedInstance().showNoConnectionAlertView(self)
            }
        }
    }
    
    //Implemente XMLParserDelegate method
    func parseWasFinished() {
        newsFeeds = feedParser.parsedDataArray
        dispatch_async(dispatch_get_main_queue()){
            self.loadingHUD.hide(true)
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
            self.tableView.reloadData()
            
            //Get the current NewsSourceString, and store the feeds dictionary into CoreData with it's name
            
        }
    }
    
    //Config loadingHUD and refreshControl
    func configHUDAndRefreshControl(){
        dispatch_async(dispatch_get_main_queue()){
            self.loadingHUD = MBProgressHUD.showHUDAddedTo(self.tableView, animated: true)
            self.loadingHUD.opacity = 0.6
            self.loadingHUD.labelText = "Loading feeds..."
        }
        //Add refreshControl to the View
        refreshControl = UIRefreshControl()
        refreshControl?.backgroundColor = UIColor.whiteColor()
        refreshControl?.addTarget(self, action: #selector(NewsTableViewController.refreshTable(_:)), forControlEvents: UIControlEvents.ValueChanged)
    }
    
    //Config the custom dropDown navigation bar
    func configDropDownMenu (){
        
        //Manully preset the menu content
        let newsSourceArray = ["NBA.com", "Hoops Rumors", "RealGM Basketball", "ESPN", "LA Times"]
        menuView = BTNavigationDropdownMenu(navigationController: self.navigationController, title: newsSourceArray.first!, items: newsSourceArray)
        menuView.cellTextLabelColor = ConvenientData().lakersGoldColor
        menuView.cellTextLabelFont = UIFont(name: "HelveticaNeue-Medium", size: 14)
        self.navigationItem.titleView = menuView
        newsSoucreString = newsSourceArray.first
        
        //Config the function when user choose a dropDown item
        menuView.didSelectItemAtIndexHandler = {(indexPath: Int) -> () in
            
            self.tableView.addSubview(self.loadingHUD)
            self.loadingHUD.show(true)
            
            //Help function
            func switchNewsFeed(){
                self.newsSoucreString = newsSourceArray[indexPath]
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)){
                    self.startParseFeeds()
                }
            }
            
            //Parse news feed according to chosed news source
            switch newsSourceArray[indexPath]{
            case "Hoops Rumors":
                switchNewsFeed()
            case "RealGM Basketball":
                switchNewsFeed()
            case "NBA.com":
                switchNewsFeed()
            case "LA Times":
                switchNewsFeed()
            case "ESPN":
                switchNewsFeed()
            default: break
            }
        }
    }
}