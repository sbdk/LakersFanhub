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
    
    var seedParser = XMLParser()
    var loadingHUD: MBProgressHUD!
    var menuView: BTNavigationDropdownMenu!
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var newsSeeds = [[String:String]]()
    var newsSoucreString: String!
    
    @IBInspectable var titleTextColor: UIColor = UIColor.blackColor()
    @IBInspectable var subTitleTextColor: UIColor = UIColor.blackColor()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ConvenientView.sharedInstance().setDarkNaviBar(self)
        tabBarController?.tabBar.tintColor = ConvenientData().lakersPurpleColor
        
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        loadingHUD = MBProgressHUD.showHUDAddedTo(tableView, animated: true)
        loadingHUD.opacity = 0.6
        loadingHUD.labelText = "Loading feeds..."
        
        //Config the custom dropDown navigation bar
        let newsSourceArray = ["Hoops Rumors", "RealGM Basketball", "NBA.com", "ESPN", "LA Times"]
        menuView = BTNavigationDropdownMenu(navigationController: self.navigationController, title: newsSourceArray.first!, items: newsSourceArray)
        menuView.cellTextLabelColor = ConvenientData().lakersGoldColor
        menuView.cellTextLabelFont = UIFont(name: "HelveticaNeue-Medium", size: 14)
        self.navigationItem.titleView = menuView
        newsSoucreString = newsSourceArray.first
        
        //Config the function when user choose a dropDown item
        menuView.didSelectItemAtIndexHandler = {(indexPath: Int) -> () in
            
            //Step-1: show the HUD loading view
            self.tableView.addSubview(self.loadingHUD)
            self.loadingHUD.show(true)
            
            //Help function prepared for step-2
            func switchNewsFeed(){
                self.newsSoucreString = newsSourceArray[indexPath]
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)){
                    self.startParseFeeds()
                }
            }
            
            //Step-2: parse news feed according to chosed news source
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
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)){
            self.startParseFeeds()
        }
        refreshControl?.backgroundColor = UIColor.whiteColor()
        refreshControl?.addTarget(self, action: #selector(NewsTableViewController.refreshTable(_:)), forControlEvents: UIControlEvents.ValueChanged)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsSeeds.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("newsTableViewCell") as! NewsTableViewCell
        let feedDic = newsSeeds[indexPath.row]
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
        let feedDic = newsSeeds[indexPath.row]
        let controller = self.storyboard?.instantiateViewControllerWithIdentifier("NewsDetailViewController") as! NewsDetailViewController
        controller.feedURLString = feedDic["link"]!
        navigationController?.pushViewController(controller, animated: true)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
    }
    
    //Implemente XMLParserDelegate method
    func parseWasFinished() {
        newsSeeds = seedParser.parsedDataArray
        dispatch_async(dispatch_get_main_queue()){
            self.loadingHUD.hide(true)
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
            self.tableView.reloadData()
        }
    }
    
    //Action fucntion for pull-down-refresh
    func refreshTable(refreshControl: UIRefreshControl){
        newsSeeds = [[String:String]]()
        tableView.reloadData()
        startParseFeeds()
        refreshControl.endRefreshing()
    }
    
    //Help function for XMLParser
    func startParseFeeds(){
        seedParser.parsedDataArray = []
        seedParser.currentDataDic = [String:String]()
        let url = NSURL(string: ConvenientData().newsSourceDict[newsSoucreString]!)
        seedParser.delegate = self
        seedParser.parseWithURL(url!)
    }
}