//
//  CloestFansBrowserView.swift
//  Lakers Fanhub
//
//  Created by Li Yin on 4/28/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ClosestFansBrowserViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MCManagerBrowserDelegate, MCManagerSessionDelegate {
    
    @IBOutlet weak var browserTableView: UITableView!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var browserActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var browserViewTopLabel: UILabel!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var cellDetailText: String!
    var searchingPeer: Bool = true
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if searchingPeer{
            browserViewTopLabel.text = "searching"
        }else{
            browserViewTopLabel.text = "connecting"
        }
        cellDetailText = "Touch to connect"
        browserTableView.delegate = self
        browserTableView.dataSource = self
        appDelegate.mcManager.browserDelegate = self
        appDelegate.mcManager.sessionDelegate = self
        browserActivityIndicator.startAnimating()
        appDelegate.mcManager.browser.startBrowsingForPeers()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appDelegate.mcManager.foundPeers.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("browserTableCell")! as UITableViewCell
        let peerID = appDelegate.mcManager.foundPeers[indexPath.row]
        cell.textLabel?.text = peerID.displayName
        
        if appDelegate.mcManager.connectedPeers.containsObject(peerID){
            cell.detailTextLabel?.text = "connected 😎"
        } else {
            cell.detailTextLabel?.text = cellDetailText
        }
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        let peerID = appDelegate.mcManager.foundPeers[indexPath.row]
        
        if appDelegate.mcManager.connectedPeers.containsObject(peerID){
            //do noting if the found peer has already connected
        } else {
            cell!.detailTextLabel!.text = "request sent...😐"
            appDelegate.mcManager.browser.invitePeer(peerID, toSession: appDelegate.mcManager.session, withContext: nil, timeout: 10)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func foundPeer() {
        print("find a peer, reaload tableView")
        browserTableView.reloadData()
    }
    
    func lostPeer() {
        print("lost a peer, reload tableview")
        browserTableView.reloadData()
    }
    
    //implemente MCManagerSessionDelegate
    func connectedWithPeer(peerID: MCPeerID) {
        cellDetailText = "connected 😎"
        print(cellDetailText)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func connectingWithPeer() {
        cellDetailText = "connecting...😍"
        dispatch_async(dispatch_get_main_queue()){
            self.browserTableView.reloadData()
        }
    }
    
    func notConnectedWithPeer(peerID: MCPeerID) {
        cellDetailText = "connect failed 😭"
        dispatch_async(dispatch_get_main_queue()){
            self.browserTableView.reloadData()
        }
    }
    
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
