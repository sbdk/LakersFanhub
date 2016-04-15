//
//  ClosestFansViewController.swift
//  Lakers Fanhub
//
//  Created by Li Yin on 4/14/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ClosestFansViewController: UIViewController, MCBrowserViewControllerDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var deviceNameTextField: UITextField!
    @IBOutlet weak var visableSwitch: UISwitch!
    @IBOutlet weak var connectedDeviceTableView: UITableView!
    @IBOutlet weak var disconnectButton: UIButton!
    
    var mcManager: MCManager!
    var connectedDevices: NSMutableArray!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        deviceNameTextField.delegate = self
        connectedDeviceTableView.delegate = self
        connectedDeviceTableView.dataSource = self
        connectedDevices = []
        mcManager = MCManager.sharedInstance()
        mcManager.setupPeerAndSessionWithDisplayName(UIDevice.currentDevice().name)
        mcManager.advertiseSelf(visableSwitch.on)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ClosestFansViewController.peerDidChangeStateWithNotification(_:)), name: "MCDidChangeStateNotification", object: nil)
    }
    
    
    @IBAction func browseForDevices(sender: AnyObject) {
        
        mcManager.setupMCBrowser()
        mcManager.browser.delegate = self
        self.presentViewController(mcManager.browser, animated: true, completion: nil)
        
    }
    
    
    @IBAction func toggleVisiblity(sender: AnyObject) {
        mcManager.advertiseSelf(visableSwitch.on)
    }
    
    @IBAction func disconnect(sender: AnyObject) {
        
    }

    func browserViewControllerDidFinish(browserViewController: MCBrowserViewController) {
        mcManager.browser.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController) {
        mcManager.browser.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        deviceNameTextField.resignFirstResponder()
        mcManager.peerID = nil
        mcManager.session = nil
        mcManager.browser = nil
        
        if visableSwitch.on {
            mcManager.advertiser.stop()
        }
        mcManager.advertiser = nil
        mcManager.setupPeerAndSessionWithDisplayName(deviceNameTextField.text!)
        mcManager.advertiseSelf(visableSwitch.on)
        
        return true
    }
    
    func peerDidChangeStateWithNotification(notification: NSNotification){
        let peerID = notification.userInfo!["peerID"] as! MCPeerID
        let peerDisplayName = peerID.displayName
        let state = notification.userInfo!["state"] as! Int
        
        if state != MCSessionState.Connecting.rawValue {
            if state == MCSessionState.Connected.rawValue {
                connectedDevices.addObject(peerDisplayName)
            }
            else if state == MCSessionState.NotConnected.rawValue {
                if connectedDevices.count > 0 {
                    let indexOfPeer = connectedDevices.indexOfObject(peerDisplayName)
                    connectedDevices.removeObjectAtIndex(indexOfPeer)
                }
            }
            
            connectedDeviceTableView.reloadData()
            var peerExist = (mcManager.session.connectedPeers.count == 0)
            disconnectButton.enabled = !peerExist
            deviceNameTextField.enabled = peerExist
        }
    }
}
