//
//  ClosestFansViewController.swift
//  Lakers Fanhub
//
//  Created by Li Yin on 4/14/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit
import CoreData
import MultipeerConnectivity
//import CoreBluetooth

class ClosestFansViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate, MCManagerInvitationDelegate, NSFetchedResultsControllerDelegate {
    @IBOutlet weak var deviceNameTextField: UITextField!
    @IBOutlet weak var visibleSwitch: UISwitch!
    @IBOutlet weak var connectedDeviceTableView: UITableView!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var browserButton: UIButton!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var switchView: UIView!
    @IBOutlet weak var chatHistoryEnterView: UIView!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let defaults = NSUserDefaults.standardUserDefaults()
    var storedPeerNames: Dictionary = [String:String]()
    /*
     We will store three objects into userDefault:
      1, visibleSwitch status(on or off), with key: "switchStatus"
      2, custom Chat ID set by user, with key: "customChatID"
      3, unread messages count for specific peer, with dynamic key: specificPeer.displayName
    */
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //make sure tableView is always up-to-date when presented to user
        connectedDeviceTableView.reloadData()
        
        //If there is still peer connected, user can't change device name
        if self.appDelegate.mcManager.connectedPeers.count > 0 {
            self.deviceNameTextField.enabled = false
        }
        
//        fetchedResultController.delegate = self
//        do{
//            try fetchedResultController.performFetch()
//            let fetchedResult = self.fetchedResultController.fetchedObjects as! [ChatPeer]
//            storedPeerNames = [:]
//            for peer in fetchedResult{
//                storedPeerNames[peer.peerName] = peer.peerName
//            }
//        } catch{print(error)}
        
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
        helpButton.showsTouchWhenHighlighted = true
        switchView.layer.borderWidth = 1.0
        switchView.layer.borderColor = UIColor.whiteColor().CGColor
        
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
            
            //Make this viewController listen to lostConnection notification and successConnection notification
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ClosestFansViewController.handleLostConnection(_:)), name: "lostConnectionWithPeer", object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ClosestFansViewController.handleSuccessConnection(_:)), name: "connectedWithPeer", object: nil)
            //Make this viewController listen to receive message notification
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ClosestFansViewController.handleMCReceivedDataWithNotification(_:)), name: "receivedMCDataNotification", object: nil)
            
            //Add a tapRecognizer to chatHistoryEnterView
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ClosestFansViewController.handleSingleTap))
            tapRecognizer.numberOfTapsRequired = 1
            self.chatHistoryEnterView.addGestureRecognizer(tapRecognizer)
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
        
        //Check whether this peer has unread messages count stored in userDefault
        if defaults.valueForKey(peerID.displayName) != nil {
            cell.badgeLabel.text = String(defaults.valueForKey(peerID.displayName)!)
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
        
        let fetchController = peerFetchController(peerID.displayName)
        do{
            try fetchController.performFetch()
        } catch{print(error)}
        
        //Reset unread message count for this peerID
        defaults.setValue(nil, forKey: peerID.displayName)
        
        //Present the ChatView
        let controller = storyboard?.instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
        let selectedPeer = (fetchController.fetchedObjects as! [ChatPeer]).first!
//        controller.peerID = peerID
        controller.chatPeer = selectedPeer
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
    
    //Config helpButton action
    @IBAction func callForHelp(sender: AnyObject) {
        
        let helpView = self.storyboard?.instantiateViewControllerWithIdentifier("HelpViewController") as! HelpViewController
        helpView.modalPresentationStyle = .Popover
        helpView.popoverPresentationController?.delegate = self

        self.presentViewController(helpView, animated: true, completion: nil)
        if let popView = helpView.popoverPresentationController{
            let sourceView = sender as! UIView
            popView.sourceView = sourceView
            popView.sourceRect = sourceView.bounds
            popView.permittedArrowDirections = .Down
            helpView.preferredContentSize = CGSizeMake(self.view.bounds.width - 50, self.view.bounds.height - 100)
        }
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
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
    
    //Once a peer has connected, add Peer info into CoreData
    func handleSuccessConnection(notification: NSNotification){
        let peerID = notification.object as! MCPeerID
        
        //Perform a fetch to get stored ChatPeers
        let fetchController = peerFetchController(peerID.displayName)
        do{
            try fetchController.performFetch()
        } catch{print(error)}
        
        dispatch_async(dispatch_get_main_queue()){
            
            //If the connected peer has previously stored in CoreData, update it's peerID info
            if let connectedPeer = (fetchController.fetchedObjects as! [ChatPeer]).first {
                connectedPeer.peerID = peerID
                CoreDataStackManager.sharedInstance().saveContext()
            }
            //If the connected peer is a new peer, add this ChatPeer object into CoreData
            else {
                let newPeer = ChatPeer(newPeerID: peerID, messagesArray: nil, context: self.sharedContext)
                self.sharedContext.insertObject(newPeer)
                CoreDataStackManager.sharedInstance().saveContext()
            }
        }
    }
    
    //Reaction fucntion used for received Message Notification
    func handleMCReceivedDataWithNotification(notification: NSNotification){
        
        let receivedDataDictionary = notification.object as! [String:AnyObject]
        
        // Extract the data and the sender's MCPeerID from the received dictionary.
        let data = receivedDataDictionary["data"] as? NSData
        let fromPeer = receivedDataDictionary["fromPeer"] as! MCPeerID
        
        let fetchController = peerFetchController(fromPeer.displayName)
        do{
            try fetchController.performFetch()
        } catch{print(error)}
        
        let sourcePeer = (fetchController.fetchedObjects as! [ChatPeer]).first!
        //Update unread message count for specific peer and save this info into userDefault
        dispatch_async(dispatch_get_main_queue()){
            if self.defaults.valueForKey(fromPeer.displayName) != nil {
                var count = self.defaults.valueForKey(fromPeer.displayName) as! Int
                count += 1
                self.defaults.setValue(count, forKey: fromPeer.displayName)
            } else {
                self.defaults.setValue(1, forKey: fromPeer.displayName)
            }
            self.connectedDeviceTableView.reloadData()
        }

        // Convert the data (NSData) into a Dictionary object.
        let dataDictionary = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as! [String:String]
        
        // Check if there's an entry with the "message" key.
        if let message = dataDictionary["message"] {
            
            // Make sure that the message is other than "_end_chat_".
            if message != "chat is ended by the other party"{
                
                dispatch_async(dispatch_get_main_queue()){
                    let receivedMessage = ChatMessage(sender: fromPeer.displayName, body: message, context: self.sharedContext)
                    receivedMessage.messagePeer = sourcePeer
                    self.sharedContext.insertObject(receivedMessage)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
            else{
                //in this case, only post the last message
                dispatch_async(dispatch_get_main_queue()){
                    let receivedMessage = ChatMessage(sender: nil, body: message, context: self.sharedContext)
                    receivedMessage.messagePeer = sourcePeer
                    self.sharedContext.insertObject(receivedMessage)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
        }
    }
    
    //Help function used to store incoming message into dictionary
//    func storeIncomingMessages(fromPeer: MCPeerID, messageDictionary: [String:String]){
//        var tempMessagesArray = [[String:String]]()
////        var tempMessagesArray: NSMutableArray = []
//        if appDelegate.mcManager.chatHistoryDict[fromPeer.displayName] != nil{
//            //If user already have chat history with this peer, fetch the stored chat messages array to store newly recieved message
//            tempMessagesArray = (appDelegate.mcManager.chatHistoryDict?[fromPeer.displayName])! as! [[String:String]]
//            tempMessagesArray.append(messageDictionary)
//        } else {
//            //If it's the first message that user received from this connected peer, creat a empty messages array to store this message
//            tempMessagesArray.append(messageDictionary)
//        }
//        //After storing the incoming message, update the ChatHistory dictionary
//        appDelegate.mcManager.chatHistoryDict[fromPeer.displayName] = tempMessagesArray
//        
//        
//        //First check whether this peer has record in CoreData
//        //If this peer has previous stored chat history, first remove it from CoreData
////        if storedPeerNames[fromPeer.displayName] != nil{
////            
////        }
////        let fetchedResult = self.fetchedResultController.fetchedObjects as! [ChatPeer]
////        for peer in fetchedResult{
////            if peer.peerName == fromPeer.displayName{
////            }
////        }
//        
////        if fetchedResultController.fetchedObjects?.first != nil {
////            let fetchedResult = self.fetchedResultController.fetchedObjects as! [ChatPeer]
////            
////        }
//        
//        //Then stored the updated chat history into CoreData
////        let updatedChatPeer = ChatPeer(chatingPeer: peerID.displayName, messagesArray: messagesArray, context: sharedContext)
////        sharedContext.insertObject(updatedChatPeer)
////        CoreDataStackManager.sharedInstance().saveContext()
//    }
    
    //Set a max length for custom ChatID
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let maxLength = 12
        let currentString: NSString = textField.text!
        let newString: NSString =
            currentString.stringByReplacingCharactersInRange(range, withString: string)
        return newString.length <= maxLength
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
    
    //Config the TapRecognizer reponse fucntion
    func handleSingleTap(recognizer: UITapGestureRecognizer) {
        ConvenientView.sharedInstance().showAlertView("this works", message: "haha", hostView: self)
    }
    
    
    //Set lazy variable for CoreData
    lazy var sharedContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    
    func peerFetchController(predicatePeerName: String) -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest(entityName: "ChatPeer")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastChatTime", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "peerName == %@", predicatePeerName)
        let fetchedRequestController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedRequestController.delegate = self
        return fetchedRequestController
    }
    
    //implemente FetchedResultController Delegate Method
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
                    atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            break
        case .Delete:
            break
        default:
            return
        }
    }
    //
    // This is the most interesting method. Take particular note of way the that newIndexPath
    // parameter gets unwrapped and put into an array literal: [newIndexPath!]
    //
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType,newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            break
        case .Delete:
            break
        case .Update:
            break
        case .Move:
            break
        }
    }
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
    }
}
