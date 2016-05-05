//
//  ChatViewController.swift
//  Lakers Fanhub
//
//  Created by Li Yin on 5/3/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ChatViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    
    var messagesArray = [[String:String]]()
    var peerID: MCPeerID!
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messageTextField.delegate = self
        chatTableView.delegate = self
        chatTableView.dataSource = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.handleMCReceivedDataWithNotification(_:)), name: "receivedMCDataNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.handleLostConnection(_:)), name: "lostConnectionWithPeer", object: nil)
        
        let endChatButton = UIBarButtonItem(title: "End Chat", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(ChatViewController.endChat(_:)))
        navigationItem.rightBarButtonItem = endChatButton
        
        //auto adjust table row height
        chatTableView.estimatedRowHeight = 60.0
        chatTableView.rowHeight = UITableViewAutomaticDimension

        // Do any additional setup after loading the view.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messagesArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("messageCell")! as UITableViewCell
        cell.detailTextLabel!.text = ""
        
        let currentMessage = messagesArray[indexPath.row] as [String:String]
        if let sender = currentMessage["sender"] {
            var senderLabelText: String
            var senderColor: UIColor
            
            if sender == "self"{
                senderLabelText = "I said:"
                senderColor = UIColor.purpleColor()
            }
            else{
                senderLabelText = sender + " said:"
                senderColor = UIColor.orangeColor()
            }
            
            cell.detailTextLabel?.text = senderLabelText
            cell.detailTextLabel?.textColor = senderColor
        }
        
        if let message = currentMessage["message"] {
            cell.textLabel?.text = message
        }
        
        return cell
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        //dismiss the keyboard
        textField.resignFirstResponder()
        
        //first send out this message dictionary to connected peer
        let messageDictionary: [String: String] = ["message": (messageTextField?.text)!]
        if appDelegate.mcManager.sendData(dictionaryWithData: messageDictionary, toPeer: peerID){
            
            //then add this message dictionary to local ChatTableView, with extra user info added into dictionary
            var dictionary: [String: String] = ["sender": "self", "message": (messageTextField?.text)!]
            messagesArray.append(dictionary)
            
            self.updateTableView()
        }
        else{
            print("Could not send data")
        }
        textField.text = ""
        return true
    }
    
    //Custom convenient function
    func updateTableView(){
        chatTableView.reloadData()
        
        //Check whether the table contentSize is bigger than table creen size, if so, scroll the tableview to most current row
        if chatTableView.contentSize.height > chatTableView.frame.size.height {
            chatTableView.scrollToRowAtIndexPath(NSIndexPath(forRow: messagesArray.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
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
                var messageDictionary: [String: String] = ["sender": fromPeer.displayName, "message": message]
                
                // Add this dictionary to the messagesArray array.
                messagesArray.append(messageDictionary)
                
                // Reload the tableview data and scroll to the bottom using the main thread.
                dispatch_async(dispatch_get_main_queue()){
                    self.updateTableView()
                }
            }
            else{
                //in this case, only post the last message
                var messageDictionary: [String:String] = ["message": message]
                messagesArray.append(messageDictionary)
                dispatch_async(dispatch_get_main_queue()){
                    self.updateTableView()
                }
            }
        }
    }
    
    func endChat(sender: AnyObject){
        print("end chat")
        let messageDictionary: [String: String] = ["message": "chat is ended by the other party"]
        if appDelegate.mcManager.sendData(dictionaryWithData: messageDictionary, toPeer: peerID){
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    func handleLostConnection(notification: NSNotification) {
        
        //whenever user lost connection with a peer, we need to check whether it's the current chatting peer, if so, present a alertView and return to previous view
        if (notification.object) as! MCPeerID == peerID {
            dispatch_sync(dispatch_get_main_queue()){
                let alterView = UIAlertController(title: "Lost connection", message: "will return to previous page", preferredStyle: UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel){(OKAction) -> Void in self.navigationController?.popViewControllerAnimated(true)
                }
                alterView.addAction(okAction)
                self.presentViewController(alterView, animated: true, completion: nil)
            }
        }
    }
}
