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


class NewsTableViewController: UITableViewController, XMLParserDelegate {
    
    var seedParser = XMLParser()
    var loadingHUD: MBProgressHUD!
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var newsSeeds = [[String:String]]()
    
    @IBInspectable var titleTextColor: UIColor = UIColor.blackColor()
    @IBInspectable var subTitleTextColor: UIColor = UIColor.blackColor()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadingHUD = MBProgressHUD()
        tableView.addSubview(loadingHUD)
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        loadingHUD.mode = MBProgressHUDMode.Indeterminate
        loadingHUD.dimBackground = true
        loadingHUD.labelText = "Loading news feeds..."
        loadingHUD.show(true)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)){
            self.startParseFeeds()
        }
        refreshControl?.backgroundColor = ConvenientData().lakersPurpleColor
        refreshControl?.tintColor = ConvenientData().lakersGoldColor
        refreshControl?.addTarget(self, action: #selector(NewsTableViewController.refreshTable(_:)), forControlEvents: UIControlEvents.ValueChanged)
  
//        tableView.cellLayoutMarginsFollowReadableWidth = false
//        tableView.separatorInset = UIEdgeInsetsZero
//        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.contentInset = UIEdgeInsetsMake(0, -8, 0, 0)
//        tableView.cellLayoutMarginsFollowReadableWidth = false

    }
    
    func parseWasFinished() {
        
        print("parsed Finished successfully, reload tableData")
        newsSeeds = seedParser.parsedDataArray
        dispatch_async(dispatch_get_main_queue()){
            self.loadingHUD.hide(true)
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
            self.tableView.reloadData()
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsSeeds.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("newsTableViewCell") as! NewsTableViewCell
        let feedDic = newsSeeds[indexPath.row]
        cell.imageView!.image = UIImage(named: "HoopsRumors")
        ConvenientView.sharedInstance().setLabel(cell.cellTitle, fontName: "HelveticaNeue-Medium", size: 14, color: titleTextColor)
        cell.cellTitle.text = feedDic["title"]
        
        ConvenientView.sharedInstance().setLabel(cell.cellAuthor, fontName: "HelveticaNeue-Light", size: 12, color: subTitleTextColor)
        cell.cellAuthor.text = feedDic["name"]
        
        ConvenientView.sharedInstance().setLabel(cell.cellFeedPublished, fontName: "HelveticaNeue-Light", size: 12, color: subTitleTextColor)
        cell.cellFeedPublished.text = feedDic["published"]

//        cell.preservesSuperviewLayoutMargins = false
//        cell.layoutMargins = UIEdgeInsetsZero

        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let feedDic = newsSeeds[indexPath.row]
        let controller = self.storyboard?.instantiateViewControllerWithIdentifier("NewsDetailViewController") as! NewsDetailViewController
        controller.feedURLString = feedDic["link"]!
        navigationController?.pushViewController(controller, animated: true)
        
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func startParseFeeds(){
        let url = NSURL(string: "http://www.hoopsrumors.com/los-angeles-lakers/feed/atom")
        seedParser.delegate = self
        seedParser.parseWithURL(url!)
    }
    
    func refreshTable(refreshControl: UIRefreshControl){
        startParseFeeds()
        refreshControl.endRefreshing()
    }
}