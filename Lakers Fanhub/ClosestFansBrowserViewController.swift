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
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var cellDetailText: String!
    enum detailLabelCase {case connectting, notConnected, failed}
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        cell.textLabel?.text = appDelegate.mcManager.foundPeers[indexPath.row].displayName
        cell.detailTextLabel?.text = cellDetailText
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell!.detailTextLabel!.text = "connecting..."
        
        let selectedPeer = appDelegate.mcManager.foundPeers[indexPath.row] as MCPeerID
        appDelegate.mcManager.browser.invitePeer(selectedPeer, toSession: appDelegate.mcManager.session, withContext: nil, timeout: 10)
        
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
    
    
    func connectedWithPeer(peerID: MCPeerID) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func connectingWithPeer() {
//        cellDetailText = "connecting..."
//        browserTableView.reloadData()
    }
    
    func notConnectedWithPeer() {
        print("not connected to session")
        cellDetailText = "connect failed"
        browserTableView.reloadData()
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
