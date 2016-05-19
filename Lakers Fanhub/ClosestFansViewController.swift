//
//  ClosestFansViewController.swift
//  Lakers Fanhub
//
//  Created by Li Yin on 4/14/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit
import MultipeerConnectivity
//import CoreBluetooth

class ClosestFansViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, MCManagerInvitationDelegate {
    @IBOutlet weak var deviceNameTextField: UITextField!
    @IBOutlet weak var visibleSwitch: UISwitch!
    @IBOutlet weak var connectedDeviceTableView: UITableView!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var browserButton: UIButton!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let defaults = NSUserDefaults.standardUserDefaults()
    
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
        //Set the background view for connectedDeviceTableView
        let backgroundImage = UIImage(named: "BeachEffect")
        let imageView = UIImageView(image: backgroundImage)
        imageView.contentMode = .ScaleAspectFill
        imageView.alpha = 0.4
        
        connectedDeviceTableView.backgroundView = imageView
        connectedDeviceTableView.tableFooterView = UIView(frame: CGRectZero)
        ConvenientView.sharedInstance().enhanceItemUI(browserButton, cornerRadius: 30.0)
        ConvenientView.sharedInstance().enhanceItemUI(disconnectButton, cornerRadius: 30.0)
        
        //Check whether user has previouly set custom ChatID, if so, reset MCManager session with this custom ChatID
        if let customChatID = self.defaults.valueForKey("customChatID") as? String {
            self.appDelegate.mcManager.peerID = nil
            self.appDelegate.mcManager.session = nil
            self.appDelegate.mcManager.setupPeerAndSessionWithDisplayName(customChatID)
            self.deviceNameTextField.text = customChatID
        }
        
        //If userDefaults has a visibleSwitch status stored, use this status to set the visibleSwitch
        if defaults.valueForKey("switchStatus") != nil {
            let switchStatus = self.defaults.valueForKey("switchStatus") as! Bool
            visibleSwitch.setOn(switchStatus, animated: false)
        }
        if  visibleSwitch.on {
            appDelegate.mcManager.advertiser.startAdvertisingPeer()
        } else {
            appDelegate.mcManager.advertiser.stopAdvertisingPeer()
        }
        
        //Put not-so-urgent task into background queue
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
            
            self.appDelegate.mcManager.invitationDelegate = self
            self.deviceNameTextField.delegate = self
            self.connectedDeviceTableView.delegate = self
            self.connectedDeviceTableView.dataSource = self
            
            //Make this viewController listen to lostConnection notification
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ClosestFansViewController.handleLostConnection(_:)), name: "lostConnectionWithPeer", object: nil)
            //Make this viewController listen to receive message notification
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ClosestFansViewController.handleMCReceivedDataWithNotification(_:)), name: "receivedMCDataNotification", object: nil)
        }
    }
    
    
    //Implemente tableView delegate
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appDelegate.mcManager.connectedPeers.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("tableViewCell", forIndexPath: indexPath) as! PeerCell
        let peerID = (appDelegate.mcManager.connectedPeers)[indexPath.row] as! MCPeerID
        cell.connectedPeerLabel!.text = peerID.displayName as String
        cell.statusLabel!.text = "connected 😎"
        
        //Config badgeLabel
        cell.badgeLabel.hidden = true
        cell.badgeLabel.clipsToBounds = true
        cell.badgeLabel.layer.cornerRadius = 8.0
        cell.badgeLabel.backgroundColor = UIColor.redColor()
        cell.badgeLabel.textColor = UIColor.whiteColor()
        if appDelegate.unreadMessageCount[peerID.displayName] != nil {
            cell.badgeLabel.text = String(appDelegate.unreadMessageCount[peerID.displayName]!)
            cell.badgeLabel.hidden = false
        }
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = UIColor(white: 1, alpha: 0.5)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let peerID = (appDelegate.mcManager.connectedPeers)[indexPath.row] as! MCPeerID
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        //Reset unread message count for this peerID
        appDelegate.unreadMessageCount.removeValueForKey(peerID.displayName)
        
        //Present the ChatView
        let controller = storyboard?.instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
        controller.peerID = peerID
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch (editingStyle) {
        case .Delete:
            let connectedPeerToRemove = appDelegate.mcManager.connectedPeers[indexPath.row] as! MCPeerID
            appDelegate.mcManager.session.cancelConnectPeer(connectedPeerToRemove)
            appDelegate.mcManager.chatHistoryDict.removeValueForKey(connectedPeerToRemove.displayName)
        default:
            break
        }
    }
    
    //Config browser action
    @IBAction func browseForDevices(sender: AnyObject) {
        let browserViewController = storyboard?.instantiateViewControllerWithIdentifier("ClosestFansBrowserViewController") as! ClosestFansBrowserViewController
        
        //indicate that browserView is presented for searching other peer, will update browserView UI accordingly
        browserViewController.searchingPeer = true
        presentViewController(browserViewController, animated: true, completion: nil)
    }
    
    //Config disconnect action
    @IBAction func disconnect(sender: AnyObject) {
        appDelegate.mcManager.session.disconnect()
        appDelegate.mcManager.connectedPeers.removeAllObjects()
        
        //Once all connected Peers are disconnected, user can change ChatID again
        deviceNameTextField.enabled = true
        
        //After disconnect all peers, also clear the chat history
        appDelegate.mcManager.chatHistoryDict.removeAll()
        connectedDeviceTableView.reloadData()
    }
    
    //Config visibleSwitch
    @IBAction func toggleVisiblity(sender: AnyObject) {
        if  visibleSwitch.on {
            appDelegate.mcManager.advertiser.startAdvertisingPeer()
        } else {
            appDelegate.mcManager.advertiser.stopAdvertisingPeer()
        }
        
        //Whenever user changed the status of visibleSwitch, save new stauts into UserDefaults to preserve this change
        defaults.setObject(visibleSwitch.on, forKey: "switchStatus")
    }
    
    //Implemente custom MCManger invitation delegate
    func invitationWasReceived(fromPeer: String, invitationHandler: (Bool, MCSession?) -> Void) {
        print("received invitatio from: \(fromPeer)")
        
        //First config the invitation AlertView
        let alert = UIAlertController(title: "", message: "\(fromPeer) wants to chat with you", preferredStyle: UIAlertControllerStyle.Alert)
        
        //Config accept action
        let acceptAction: UIAlertAction = UIAlertAction(title: "Accept", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
            invitationHandler(true, self.appDelegate.mcManager.session)
            
            //If user tap accept button, present a custom BroserView to show connection status
            dispatch_async(dispatch_get_main_queue()){
                let browserViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ClosestFansBrowserViewController") as! ClosestFansBrowserViewController
                
                //indicate that browserView is presented for handling invitation sent from other peer, will update browserView UI accordingly
                browserViewController.searchingPeer = false
                browserViewController.connectWithPeer = fromPeer
                
                //Present the custom browserView from App window's rootViewController, so user will get noticed anywhere from the application
                self.appDelegate.window?.rootViewController?.presentViewController(browserViewController, animated: true, completion: nil)
            }
        }
        let declineAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) {(alertAction) -> Void in
            invitationHandler(false, self.appDelegate.mcManager.session)
        }
        alert.addAction(declineAction)
        alert.addAction(acceptAction)
        
        //Present the invitation AlertView from App window's rootViewController, so user will get noticed anywhere from the application
        dispatch_async(dispatch_get_main_queue()){
            self.appDelegate.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    //Reaction function used for lostConnection notification
    func handleLostConnection(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue()){
            self.connectedDeviceTableView.reloadData()
            
            //When all peers lost connection, re-enable the deviceNameTextField for user to change ChatID
            if self.appDelegate.mcManager.connectedPeers.count == 0 {
                self.deviceNameTextField.enabled = true
            }
        }
    }
    
    //Reaction fucntion used for received Message Notification
    func handleMCReceivedDataWithNotification(notification: NSNotification){
        
        let receivedDataDictionary = notification.object as! [String:AnyObject]
        
        // Extract the data and the sender's MCPeerID from the received dictionary.
        let data = receivedDataDictionary["data"] as? NSData
        let fromPeer = receivedDataDictionary["fromPeer"] as! MCPeerID
        
        //Update unread message count for specific peer
        dispatch_async(dispatch_get_main_queue()){
            if var count = self.appDelegate.unreadMessageCount[fromPeer.displayName] {
                count += 1
                self.appDelegate.unreadMessageCount[fromPeer.displayName] = count
            } else {
                self.appDelegate.unreadMessageCount.updateValue(1, forKey: fromPeer.displayName)
            }
            self.connectedDeviceTableView.reloadData()
        }

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
        if appDelegate.mcManager.chatHistoryDict[fromPeer.displayName] != nil{
            //If user already have chat history with this peer, fetch the stored chat messages array to store newly recieved message
            tempMessagesArray = (appDelegate.mcManager.chatHistoryDict?[fromPeer.displayName])! as! [[String:String]]
            tempMessagesArray.append(messageDictionary)
        } else {
            //If it's the first message that user received from this connected peer, creat a empty messages array to store this message
            tempMessagesArray.append(messageDictionary)
        }
        //After storing the incoming message, update the ChatHistory dictionary
        appDelegate.mcManager.chatHistoryDict[fromPeer.displayName] = tempMessagesArray
    }

    //Implemente textField delegate method
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        //First resign the keyboard when user hit return key
        deviceNameTextField.resignFirstResponder()
        
        //If user tap the textField but don't input anything, use default device name
        var resetDeviceName: String!
        if deviceNameTextField.text! == "" {
            resetDeviceName = UIDevice.currentDevice().name
            defaults.removeObjectForKey("customChatID")
        } else {
            resetDeviceName = deviceNameTextField.text!
            //Save user's custom ChatID into UserDefault to preserve this change
            defaults.setObject(resetDeviceName, forKey: "customChatID")
        }
        
        //If MCManger advertiser is on, first stop it and then reset it, since user will use a new ChatID to advitise with
        if visibleSwitch.on {
            appDelegate.mcManager.advertiser.stopAdvertisingPeer()
        }
        appDelegate.mcManager.advertiser = nil
        
        //Upon user hit return key, reset peerID and session using the new ChatID
        appDelegate.mcManager.peerID = nil
        appDelegate.mcManager.session = nil
        appDelegate.mcManager.setupPeerAndSessionWithDisplayName(resetDeviceName)
        
        //After reset is done, resume advertiser if it's switch is on
        if visibleSwitch.on {
            appDelegate.mcManager.advertiser.startAdvertisingPeer()
        }
        return true
    }
}
