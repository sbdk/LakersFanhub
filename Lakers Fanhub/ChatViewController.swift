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
    
    var messagesArray = [Dictionary<String,String>]()
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messageTextField.delegate = self
        chatTableView.delegate = self
        chatTableView.dataSource = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.handleMCReceivedDataWithNotification(_:)), name: "receivedMCDataNotification", object: nil)
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
        textField.resignFirstResponder()
        
        let messageDictionary: [String: String] = ["message": (messageTextField?.text)!]
        
        if appDelegate.mcManager.sendData(dictionaryWithData: messageDictionary, toPeer: (appDelegate.mcManager.session.connectedPeers[0] as MCPeerID)){
            
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
    
    func updateTableView(){
        chatTableView.reloadData()
        
        if chatTableView.contentSize.height > chatTableView.frame.size.height {
            chatTableView.scrollToRowAtIndexPath(NSIndexPath(forRow: messagesArray.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        }
    }
    
    func handleMCReceivedDataWithNotification(notification: NSNotification){
        
        let receivedDataDictionary = notification.object as! [String:AnyObject]
        
        // "Extract" the data and the source peer from the received dictionary.
        let data = receivedDataDictionary["data"] as? NSData
        let fromPeer = receivedDataDictionary["fromPeer"] as! MCPeerID
        
        // Convert the data (NSData) into a Dictionary object.
        let dataDictionary = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as! [String:String]
        
        // Check if there's an entry with the "message" key.
        if let message = dataDictionary["message"] {
            // Make sure that the message is other than "_end_chat_".
            if message != "_end_chat_"{
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
        let messageDictionary: [String: String] = ["message": "_end_chat_"]
        if appDelegate.mcManager.sendData(dictionaryWithData: messageDictionary, toPeer: appDelegate.mcManager.session.connectedPeers[0] as MCPeerID){
//            navigationController?.popViewControllerAnimated(true)
////            self.appDelegate.mcManager.session.disconnect()
            
        }
    }

}
