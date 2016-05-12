//
//  ChatViewController.swift
//  Lakers Fanhub
//
//  Created by Li Yin on 5/3/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ChatViewController: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var messageInputTextView: UITextView!
    
    var messagesArray = [[String:String]]()
    var peerID: MCPeerID!
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    //keyboard config
    var tapRecognizer: UITapGestureRecognizer? = nil
    var keyboardAdjusted = false
    var lastKeyboardOffset : CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messageInputTextView.delegate = self
        messageInputTextView.returnKeyType = UIReturnKeyType.Send
        messageInputTextView.enablesReturnKeyAutomatically = true
        messageInputTextView.layer.cornerRadius = 10.0
        messageInputTextView.layer.borderColor = UIColor.grayColor().CGColor
        messageInputTextView.layer.borderWidth = 1.0
        chatTableView.delegate = self
        chatTableView.dataSource = self
        chatTableView.separatorStyle = UITableViewCellSeparatorStyle.None
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.handleMCReceivedDataWithNotification(_:)), name: "receivedMCDataNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.handleLostConnection(_:)), name: "lostConnectionWithPeer", object: nil)
        subscribeToKeyboardNotifications()
        
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ChatViewController.handleSingleTap))
        tapRecognizer?.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapRecognizer!)
        
        let endChatButton = UIBarButtonItem(title: "End Chat", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(ChatViewController.endChat(_:)))
        navigationItem.rightBarButtonItem = endChatButton
        
        //auto adjust table row height
        chatTableView.rowHeight = UITableViewAutomaticDimension
        chatTableView.estimatedRowHeight = 50.0

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.hidden = true
        
        //If there is a messageArray object stored for this peerID, use this stored object to populate tableView
        if (appDelegate.chatMessagesDict?[peerID.displayName]) != nil{
            print("use stored messaged array")
            messagesArray = (appDelegate.chatMessagesDict?[peerID.displayName])! as! [[String:String]]
        } else {
            messagesArray = []
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.hidden = false
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messagesArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let currentMessage = messagesArray[indexPath.row] as [String:String]
        let messageBody = currentMessage["message"] ?? ""
        let messageViewMaxWidth: CGFloat = 240.0
        
        if let sender = currentMessage["sender"] {
            if sender == "self"{
                //implemente outgoing message
                let cell = tableView.dequeueReusableCellWithIdentifier("sentMessageCell")! as! ChatMessageTableCell
                cell.sentMessageView.text = messageBody
                cell.sentMessageView.backgroundColor = UIColor.purpleColor()
                cell.sentMessageView.textColor = UIColor.whiteColor()
                cell.sentMessageView.layer.cornerRadius = 10.0
                if cell.sentMessageView.attributedText.size().width < messageViewMaxWidth {
                    cell.sentMessageViewWidth.constant = cell.sentMessageView.attributedText.size().width + 10
                } else {
                    cell.sentMessageViewWidth.constant = 240.0
                }
                return cell
                
            } else {
                //implemente incoming message
                let cell = tableView.dequeueReusableCellWithIdentifier("receivedMessageCell")! as! ChatMessageTableCell
                cell.receivedMessageView.backgroundColor = UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1.0)
                cell.receivedMessageView.textColor = UIColor.blackColor()
                cell.receivedMessageView.layer.cornerRadius = 10.0
                cell.receivedMessageView.text = messageBody
                if cell.receivedMessageView.attributedText.size().width < messageViewMaxWidth {
                    cell.receivedMessageViewWidth.constant = cell.receivedMessageView.attributedText.size().width + 10
                } else {
                    cell.receivedMessageViewWidth.constant = 240.0
                }
                return cell
            }
        } else {
            //implemente end-of-chat message
            let cell = tableView.dequeueReusableCellWithIdentifier("receivedMessageCell")! as! ChatMessageTableCell
            cell.receivedMessageView.backgroundColor = UIColor.whiteColor()
            cell.receivedMessageView.textColor = UIColor.lightGrayColor()
            cell.receivedMessageView.layer.cornerRadius = 10.0
            cell.receivedMessageView.text = messageBody
            cell.receivedMessageViewWidth.constant = 240.0
            return cell
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n"{
            //first send out this message dictionary to connected peer
            let messageDictionary: [String: String] = ["message": (messageInputTextView?.text)!]
            if appDelegate.mcManager.sendData(dictionaryWithData: messageDictionary, toPeer: peerID){
                
                //then add this message dictionary to local ChatTableView, with extra user info added into dictionary
                let dictionary: [String: String] = ["sender": "self", "message": (messageInputTextView?.text)!]
                messagesArray.append(dictionary)
                
                self.updateTableView()
            }
            else{
                print("Could not send data")
            }
            messageInputTextView.text = ""
            messageInputTextView.resignFirstResponder()
        }
        return true
    }
    
    func textViewDidChange(textView: UITextView) {
//        
//        textView.sizeToFit()
    }
    
    
    //Custom convenient function
    func updateTableView(){
        //whenever chatView has new message to be displayed, save the current messageArray into memory, using current peerID's displayName as dictionary key.
        appDelegate.chatMessagesDict?[peerID.displayName] = messagesArray
        chatTableView.reloadData()
        
        //Check whether the table contentSize is bigger than table creen size, if so, scroll the tableview to most current row
        if chatTableView.contentSize.height > chatTableView.frame.size.height {
            chatTableView.scrollToRowAtIndexPath(NSIndexPath(forRow: messagesArray.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        }
    }
    
    //this function will be called once the session object received the data and call the notification
    func handleMCReceivedDataWithNotification(notification: NSNotification){
        
        print("received a message from other party")
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
            appDelegate.chatMessagesDict.removeValueForKey(peerID.displayName)
            appDelegate.mcManager.session.cancelConnectPeer(peerID)
        }
    }
    
    func handleLostConnection(notification: NSNotification) {
        
        //whenever user lost connection with a peer, we need to check whether it's the current chatting peer, if so, present a alertView and return to previous view
        if (notification.object) as! MCPeerID == peerID {
            dispatch_sync(dispatch_get_main_queue()){
                let alterView = UIAlertController(title: "Lost connection", message: "will exit chat window", preferredStyle: UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel){(OKAction) -> Void in self.navigationController?.popViewControllerAnimated(true)
                }
                alterView.addAction(okAction)
                self.presentViewController(alterView, animated: true, completion: nil)
            }
        }
    }
    
    func handleSingleTap(recognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
}
