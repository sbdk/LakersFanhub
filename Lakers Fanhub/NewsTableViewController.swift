//
//  NewsViewController.swift
//  Lakers Fanhub
//
//  Created by Li Yin on 4/5/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import Foundation
import UIKit


class NewsTableViewController: UITableViewController, XMLParserDelegate {
    
    var seedParser: XMLParser!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = NSURL(string: "http://www.hoopsrumors.com/los-angeles-lakers/feed/atom")
        seedParser = XMLParser()
        seedParser.delegate = self
        seedParser.parseWithURL(url!)
  
//        tableView.cellLayoutMarginsFollowReadableWidth = false
        
//        tableView.separatorInset = UIEdgeInsetsZero
//        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.contentInset = UIEdgeInsetsMake(0, -8, 0, 0)
//        tableView.cellLayoutMarginsFollowReadableWidth = false
    }
    
    func parseWasFinished() {
        
        tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return seedParser.parsedDataArray.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("newsTableViewCell") as! NewsTableViewCell
        let feedDic = seedParser.parsedDataArray[indexPath.row]
        cell.imageView!.image = UIImage(named: "HoopsRumors")
        cell.cellTitle.text = feedDic["title"]
        cell.cellAuthor.text = feedDic["name"]
        cell.cellFeedPublished.text = feedDic["published"]

//        cell.preservesSuperviewLayoutMargins = false
//        cell.layoutMargins = UIEdgeInsetsZero

        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let feedDic = seedParser.parsedDataArray[indexPath.row]
        let controller = self.storyboard?.instantiateViewControllerWithIdentifier("NewsDetailViewController") as! NewsDetailViewController
        controller.feedURLString = feedDic["link"]!
        navigationController?.pushViewController(controller, animated: true)
        
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
}