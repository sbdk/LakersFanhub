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
    @IBOutlet weak var browserButton: UIButton!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //make sure tableView is always up-to-date when presented to user
        connectedDeviceTableView.reloadData()
        
        //If there is still peer connected, user can't change device name
        if self.appDelegate.mcManager.connectedPeers.count > 0 {
            self.deviceNameTextField.enabled = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        deviceNameTextField.delegate = self
        connectedDeviceTableView.delegate = self
        connectedDeviceTableView.dataSource = self
        appDelegate.mcManager.invitationDelegate = self
        
        browserButton.layer.cornerRadius = 30.0
        disconnectButton.layer.cornerRadius = 30.0
        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ClosestFansViewController.handleLostConnection(_:)), name: "lostConnectionWithPeer", object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ClosestFansViewController.handleMCReceivedDataWithNotification(_:)), name: "receivedMCDataNotification", object: nil)
            if  self.visableSwitch.on {
                self.appDelegate.mcManager.advertiser.startAdvertisingPeer()
            } else {
                self.appDelegate.mcManager.advertiser.stopAdvertisingPeer()
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appDelegate.mcManager.connectedPeers.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("tableViewCell", forIndexPath: indexPath)
        let peerID = (appDelegate.mcManager.connectedPeers)[indexPath.row] as! MCPeerID
        cell.textLabel!.text = peerID.displayName as String
        cell.detailTextLabel!.text = "connected 😎"
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let peerID = (appDelegate.mcManager.connectedPeers)[indexPath.row] as! MCPeerID
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let controller = storyboard?.instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
        controller.peerID = peerID
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch (editingStyle) {
        case .Delete:
            let connectedPeerToRemove = appDelegate.mcManager.connectedPeers[indexPath.row] as! MCPeerID
            appDelegate.mcManager.session.cancelConnectPeer(connectedPeerToRemove)
            appDelegate.chatMessagesDict.removeValueForKey(connectedPeerToRemove.displayName)
        default:
            break
        }
    }
    
    @IBAction func browseForDevices(sender: AnyObject) {
        let browserViewController = storyboard?.instantiateViewControllerWithIdentifier("ClosestFansBrowserViewController") as! ClosestFansBrowserViewController
        
        //indicate that browserView is used for searching other peer
        browserViewController.searchingPeer = true
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
        appDelegate.mcManager.connectedPeers.removeAllObjects()
        
        //After disconnect all peers, also clear the chat history
        appDelegate.chatMessagesDict.removeAll()
        connectedDeviceTableView.reloadData()
    }
    
    //Implemente invitation delegate
    func invitationWasReceived(fromPeer: String, invitationHandler: (Bool, MCSession?) -> Void) {
        print("received invitatio from: \(fromPeer)")
        
        //Config the invitation AlertView
        let alert = UIAlertController(title: "", message: "\(fromPeer) wants to chat with you.", preferredStyle: UIAlertControllerStyle.Alert)
        let acceptAction: UIAlertAction = UIAlertAction(title: "Accept", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
            invitationHandler(true, self.appDelegate.mcManager.session)
            
            //if user tap accept button, present a Custom BroserView to show connection status
            dispatch_async(dispatch_get_main_queue()){
                let browserViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ClosestFansBrowserViewController") as! ClosestFansBrowserViewController
                
                //indicate that browserView is used for handling invitation from other peer
                browserViewController.searchingPeer = false
                self.appDelegate.window?.rootViewController?.presentViewController(browserViewController, animated: true, completion: nil)
            }
        }
        let declineAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) {(alertAction) -> Void in
            invitationHandler(false, self.appDelegate.mcManager.session)
        }
        alert.addAction(declineAction)
        alert.addAction(acceptAction)
        
        //Present the invitation Alter view
        dispatch_async(dispatch_get_main_queue()){
            self.appDelegate.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    //Help function used for lostConnection notification
    func handleLostConnection(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue()){
            self.connectedDeviceTableView.reloadData()
            
            //When all peers lost connection, re-enable the deviceNameTextField
            if self.appDelegate.mcManager.connectedPeers.count == 0 {
                self.deviceNameTextField.enabled = true
            }
        }
    }
    
    //this function will be called once the session object received the data and call the notification
    func handleMCReceivedDataWithNotification(notification: NSNotification){
        
        let receivedDataDictionary = notification.object as! [String:AnyObject]
        
        // Extract the data and the sender's MCPeerID from the received dictionary.
        let data = receivedDataDictionary["data"] as? NSData
        let fromPeer = receivedDataDictionary["fromPeer"] as! MCPeerID
        
        // Convert the data (NSData) into a Dictionary object.
        let dataDictionary = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as! [String:String]
        
        // Check if there's an entry with the "message" key.
        if let message = dataDictionary["message"] {
            
            // Make sure that the message is other than "_end_chat_".
            if message != "chat is ended by the other party"{
                
                // Create a new dictionary and set the sender and the received message to it.
                let messageDictionary: [String: String] = ["sender": fromPeer.displayName, "message": message]
                
                // Add this dictionary to the messagesArray array.
                storeIncomingMessages(fromPeer, messageDictionary: messageDictionary)
            }
            else{
                //in this case, only post the last message
                let messageDictionary: [String:String] = ["message": message]
                storeIncomingMessages(fromPeer, messageDictionary: messageDictionary)
            }
        }
    }
    
    //Help function used to store incoming message into dictionary
    func storeIncomingMessages(fromPeer: MCPeerID, messageDictionary: [String:String]){
        var tempMessagesArray = [[String:String]]()
        if appDelegate.chatMessagesDict[fromPeer.displayName] != nil{
            //If user already have chat history with this peer, fetch the stored chat messages array to store newly recieved message
            tempMessagesArray = (appDelegate.chatMessagesDict?[fromPeer.displayName])! as! [[String:String]]
            tempMessagesArray.append(messageDictionary)
        } else {
            //If it's the first message that user received from connected peer, creat a empty messages array to store this message
            tempMessagesArray.append(messageDictionary)
        }
        //After the messagesArray updated, update the chatMessages dictionary in AppDelegate
        appDelegate.chatMessagesDict[fromPeer.displayName] = tempMessagesArray
    }

    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        var resetDeviceName: String!
        //If user tap the textField but don't input anything, use default device name
        if deviceNameTextField.text! == "" {
           resetDeviceName = UIDevice.currentDevice().name
        } else {
            resetDeviceName = deviceNameTextField.text!
        }
        deviceNameTextField.resignFirstResponder()
        //If advertiser is on, first stop it and then reset it
        if visableSwitch.on {
            appDelegate.mcManager.advertiser.stopAdvertisingPeer()
        }
        appDelegate.mcManager.advertiser = nil
        
        //Upon return, reset peerID and session using user provided device name
        appDelegate.mcManager.peerID = nil
        appDelegate.mcManager.session = nil
        appDelegate.mcManager.setupPeerAndSessionWithDisplayName(resetDeviceName)
        
        //After reset is done, resume advertiser if it's switch is on
        if visableSwitch.on {
            appDelegate.mcManager.advertiser.startAdvertisingPeer()
        }
        return true
    }
}
