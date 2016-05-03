//
//  ClosestFansViewController.swift
//  Lakers Fanhub
//
//  Created by Li Yin on 4/14/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ClosestFansViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, MCManagerInvitationDelegate {
    @IBOutlet weak var deviceNameTextField: UITextField!
    @IBOutlet weak var visableSwitch: UISwitch!
    @IBOutlet weak var connectedDeviceTableView: UITableView!
    @IBOutlet weak var disconnectButton: UIButton!
    
//    var mcManager: MCManager!
    var connectedDevices: NSMutableArray!
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        connectedDevices = appDelegate.mcManager.connectedPeers
        connectedDeviceTableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        deviceNameTextField.delegate = self
        connectedDeviceTableView.delegate = self
        connectedDeviceTableView.dataSource = self
        appDelegate.mcManager.invitationDelegate = self
        connectedDevices = []
        
        if  visableSwitch.on {
            appDelegate.mcManager.advertiser.startAdvertisingPeer()
        } else {
            appDelegate.mcManager.advertiser.stopAdvertisingPeer()
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return connectedDevices.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("tableViewCell", forIndexPath: indexPath)
        let peerID = connectedDevices[indexPath.row] as! MCPeerID
        cell.textLabel!.text = peerID.displayName as String
        cell.detailTextLabel!.text = "🏀connected"
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50.0
    }
    
    func invitationWasReceived(fromPeer: String, invitationHandler: (Bool, MCSession?) -> Void) {
        print("received invitatio from: \(fromPeer)")
        let alert = UIAlertController(title: "", message: "\(fromPeer) wants to chat with you.", preferredStyle: UIAlertControllerStyle.Alert)
        let acceptAction: UIAlertAction = UIAlertAction(title: "Accept", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
            invitationHandler(true, self.appDelegate.mcManager.session)
        }
        let declineAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) {(alertAction) -> Void in
            invitationHandler(false, nil)
        }
        alert.addAction(declineAction)
        alert.addAction(acceptAction)
        
        dispatch_async(dispatch_get_main_queue()){
            self.appDelegate.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func browseForDevices(sender: AnyObject) {
        
        let browserViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ClosestFansBrowserViewController") as! ClosestFansBrowserViewController
        presentViewController(browserViewController, animated: true, completion: nil)
    }
    
    
    @IBAction func toggleVisiblity(sender: AnyObject) {
        if  visableSwitch.on {
            appDelegate.mcManager.advertiser.startAdvertisingPeer()
        } else {
            appDelegate.mcManager.advertiser.stopAdvertisingPeer()
        }
    }
    
    @IBAction func disconnect(sender: AnyObject) {
        appDelegate.mcManager.session.disconnect()
        deviceNameTextField.enabled = true
        connectedDevices.removeAllObjects()
        connectedDeviceTableView.reloadData()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        deviceNameTextField.resignFirstResponder()
        appDelegate.mcManager.peerID = nil
        appDelegate.mcManager.session = nil
        
        if visableSwitch.on {
            appDelegate.mcManager.advertiser.stopAdvertisingPeer()
        }
        appDelegate.mcManager.advertiser = nil
        appDelegate.mcManager.setupPeerAndSessionWithDisplayName(deviceNameTextField.text!)
        if visableSwitch.on {
            appDelegate.mcManager.advertiser.startAdvertisingPeer()
        }
        return true
    }
}
