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
    //Config keyboard
    var keyboardAdjusted = false
    var lastKeyboardOffset : CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ConvenientView.sharedInstance().setLightNaviBar(self)
        messageInputTextView.layer.cornerRadius = 8.0
        messageInputTextView.layer.borderColor = UIColor.whiteColor().CGColor
        messageInputTextView.layer.borderWidth = 1
        
        chatTableView.delegate = self
        chatTableView.dataSource = self
        chatTableView.separatorStyle = UITableViewCellSeparatorStyle.None
        
        //Auto adjust tableView height according to it's content size
        chatTableView.rowHeight = UITableViewAutomaticDimension
        chatTableView.estimatedRowHeight = 50.0
        
        let endChatButton = UIBarButtonItem(image: UIImage(named: "NoChat"), style: .Plain, target: self, action: #selector(ChatViewController.endChat(_:)))
        navigationItem.rightBarButtonItem = endChatButton
        
        //Put not-so-urgent task into background queue to improve ChatViewContoller load speed
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
            self.subscribeToKeyboardNotifications()
            
            //Custom keyboard return key
            self.messageInputTextView.delegate = self
            self.messageInputTextView.returnKeyType = UIReturnKeyType.Send
            self.messageInputTextView.enablesReturnKeyAutomatically = true
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.handleMCReceivedDataWithNotification(_:)), name: "receivedMCDataNotification", object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.handleLostConnection(_:)), name: "lostConnectionWithPeer", object: nil)
            
            //Add a tapRecognizer to this ChatView, user will tap screen to dismiss keyboard
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ChatViewController.handleSingleTap))
            tapRecognizer.numberOfTapsRequired = 1
            self.view.addGestureRecognizer(tapRecognizer)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.hidden = true
        navigationItem.title = peerID.displayName
        
        //If there is a messageArray object stored for this peerID, use this stored object to populate tableView
        if (appDelegate.mcManager.chatHistoryDict?[peerID.displayName]) != nil{
            messagesArray = (appDelegate.mcManager.chatHistoryDict?[peerID.displayName])! as! [[String:String]]
        } else {
            messagesArray = []
        }
        
        //Scroll ChatTableView to last row
        if messagesArray.count > 0 {
            let delay = 0.1 * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue()){
                self.chatTableView.scrollToRowAtIndexPath(NSIndexPath(forRow: self.messagesArray.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        //Upon leave ChatView, reset unread message count for this Peer, since incoming message are still counting during the Chat
        appDelegate.unreadMessageCount.removeValueForKey(peerID.displayName)
        tabBarController?.tabBar.hidden = false
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messagesArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let currentMessage = messagesArray[indexPath.row] as [String:String]
        let messageBody = currentMessage["message"]
        let messageViewMaxWidth: CGFloat = 240.0
        
        //Situation that it's a normal message
        if let sender = currentMessage["sender"] {
            if sender == "self"{
                //implemente outgoing message
                let cell = tableView.dequeueReusableCellWithIdentifier("sentMessageCell")! as! ChatSentMessageCell
                cell.sentTextView.text = messageBody
                cell.sentTextView.backgroundColor = UIColor.purpleColor()
                cell.sentTextView.textColor = UIColor.whiteColor()
                cell.sentTextView.layer.cornerRadius = 10.0
                
                //If the content size of textView is smaller than massageMaxWidth, use adjusted contentsize for this message, which will be a single line message
                if cell.sentTextView.attributedText.size().width < messageViewMaxWidth {
                    cell.sentTextViewWidth.constant = cell.sentTextView.attributedText.size().width + 10
                }
                
                //If the content size of textView is bigger than massageMaxWidth, fix the message widht to maxWidth and make this messageView muliple line
                else {
                    cell.sentTextViewWidth.constant = 240.0
                }
                return cell
                
            } else {
                //implemente incoming message
                let cell = tableView.dequeueReusableCellWithIdentifier("receivedMessageCell")! as! ChatReceivedMessageCell
                cell.receivedTextView.backgroundColor = UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1.0)
                cell.receivedTextView.textColor = UIColor.blackColor()
                cell.receivedTextView.layer.cornerRadius = 10.0
                cell.receivedTextView.text = messageBody
                if cell.receivedTextView.attributedText.size().width < messageViewMaxWidth {
                    cell.receivedTextViewWidth.constant = cell.receivedTextView.attributedText.size().width + 10
                } else {
                    cell.receivedTextViewWidth.constant = 240.0
                }
                return cell
            }
        }
        //Situation that it's the last message
        else {
            //implemente end-of-chat message
            let cell = tableView.dequeueReusableCellWithIdentifier("receivedMessageCell")! as! ChatReceivedMessageCell
            cell.receivedTextView.backgroundColor = UIColor.whiteColor()
            cell.receivedTextView.textColor = UIColor.lightGrayColor()
            cell.receivedTextView.layer.cornerRadius = 10.0
            cell.receivedTextView.text = messageBody
            cell.receivedTextViewWidth.constant = 240.0
            return cell
        }
    }
    
    
    //Implemente textView delegate method
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        //If user hit return key
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
        }
        return true
    }
    
    //Another textViewDelegate method, remove the typed-in "return" value from textView
    func textViewDidChange(textView: UITextView) {
        if messageInputTextView.text == "\n"{
            messageInputTextView.text = ""
        }
    }
    
    
    //Custom convenient function
    func updateTableView(){
        //whenever chatView has new message to be displayed, save the current messageArray into memory, using current peerID's displayName as dictionary key.
        appDelegate.mcManager.chatHistoryDict?[peerID.displayName] = messagesArray
        chatTableView.reloadData()
        chatTableView.scrollToRowAtIndexPath(NSIndexPath(forRow: messagesArray.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
    }
    
    
    //Implemente the endChat function for the endChatButton
    func endChat(sender: AnyObject){
        print("end chat")
        let messageDictionary: [String: String] = ["message": "chat is ended by the other party"]
        if appDelegate.mcManager.sendData(dictionaryWithData: messageDictionary, toPeer: peerID){
            //When user end a chat, also clear it's stored chat history
            appDelegate.mcManager.chatHistoryDict.removeValueForKey(peerID.displayName)
            appDelegate.mcManager.session.cancelConnectPeer(peerID)
        }
    }
    
    //Reaction fucntion used for received Message Notification
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
                messagesArray.append(messageDictionary)
                
                // Reload the tableview data and scroll to the bottom using the main thread.
                dispatch_async(dispatch_get_main_queue()){
                    self.updateTableView()
                }
            }
            else{
                //in this case, only post the last message
                let messageDictionary: [String:String] = ["message": message]
                messagesArray.append(messageDictionary)
                dispatch_async(dispatch_get_main_queue()){
                    self.updateTableView()
                }
            }
        }
    }
  
    //Reaction fucntion used for lostConnection Notification
    func handleLostConnection(notification: NSNotification) {
        
        //whenever user lost connection with a peer, we need to check whether it's the current chatting peer, if so, present an alertView and leave the current ChatView
        if (notification.object) as! MCPeerID == peerID {
            dispatch_sync(dispatch_get_main_queue()){
                let alterView = UIAlertController(title: "Lost connection", message: "Connection is lost, will dismiss chat window", preferredStyle: UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel){(OKAction) -> Void in self.navigationController?.popViewControllerAnimated(true)
                }
                alterView.addAction(okAction)
                self.presentViewController(alterView, animated: true, completion: nil)
            }
        }
    }
    
    //Config the TapRecognizer reponse fucntion to dismiss keyboard
    func handleSingleTap(recognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
}
