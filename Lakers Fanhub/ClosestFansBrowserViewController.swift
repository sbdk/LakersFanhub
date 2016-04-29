//
//  CloestFansBrowserView.swift
//  Lakers Fanhub
//
//  Created by Li Yin on 4/28/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit

class ClosestFansBrowserViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MCManagerDelegate {
    
    @IBOutlet weak var browserTableView: UITableView!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var browserActivityIndicator: UIActivityIndicatorView!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        browserTableView.delegate = self
        browserTableView.dataSource = self
        appDelegate.mcManager.delegate = self
        browserActivityIndicator.startAnimating()
        appDelegate.mcManager.browser.startBrowsingForPeers()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appDelegate.mcManager.foundPeers.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("browserTableCell")! as UITableViewCell
        cell.textLabel?.text = appDelegate.mcManager.foundPeers[indexPath.row].displayName
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50.0
    }
    
    func foundPeer() {
        browserTableView.reloadData()
    }
    
    
    func lostPeer() {
        browserTableView.reloadData()
    }
    
//    func invitationWasReceived(fromPeer: String)
//    
//    func connectedWithPeer(peerID: MCPeerID)
    
    
    @IBAction func cancelButtonTouched(sender: AnyObject) {
        appDelegate.mcManager.foundPeers.removeAll()
        appDelegate.mcManager.browser.stopBrowsingForPeers()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func doneButtonTouched(sender: AnyObject) {
        appDelegate.mcManager.foundPeers.removeAll()
        appDelegate.mcManager.browser.stopBrowsingForPeers()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
