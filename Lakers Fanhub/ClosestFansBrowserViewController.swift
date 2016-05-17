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
    @IBOutlet weak var browserActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var browserViewTopLabel: UILabel!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var cellDetailText: String!
    var searchingPeer: Bool = true
    var connectWithPeer: String = ""
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //prepare view UI according to the status of this browserView
        if searchingPeer{
            browserViewTopLabel.text = "Searching"
            cellDetailText = "Touch to connect"
        }else{
            browserViewTopLabel.text = "Connecting"
            browserTableView.allowsSelection = false
            cellDetailText = "connecting..."
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        browserTableView.delegate = self
        browserTableView.dataSource = self
        browserTableView.tableFooterView = UIView(frame: CGRectZero)
        appDelegate.mcManager.browserDelegate = self
        appDelegate.mcManager.sessionDelegate = self
        browserActivityIndicator.startAnimating()
        appDelegate.mcManager.browser.startBrowsingForPeers()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        appDelegate.mcManager.foundPeers.removeAll()
        appDelegate.mcManager.browser.stopBrowsingForPeers()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appDelegate.mcManager.foundPeers.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let peerID = appDelegate.mcManager.foundPeers[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("browserTableCell")! as! PeerCell
        cell.foundPeerLabel?.text = peerID.displayName
        
        if appDelegate.mcManager.connectedPeers.containsObject(peerID){
            cell.connectStatusLabel?.text = "connected 😎"
        } else if peerID.displayName == connectWithPeer {
            cell.connectStatusLabel?.text = cellDetailText
        } else {
            cell.connectStatusLabel?.text = "Touch to connect"
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //By disable selection for tableView after selecting a row, make sure only one invitation is been sent and send only once
        browserTableView.allowsSelection = false
        
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! PeerCell
        let peerID = appDelegate.mcManager.foundPeers[indexPath.row]
        
        //Set the current connecting peer info with selected peerID
        connectWithPeer = peerID.displayName
        
        if appDelegate.mcManager.connectedPeers.containsObject(peerID){
            //do noting if the found peer has already connected
        } else {
            cell.connectStatusLabel!.text = "request sent...😐"
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
        dispatch_async(dispatch_get_main_queue()){
           self.dismissViewControllerAnimated(true, completion: nil)
        }
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
}
