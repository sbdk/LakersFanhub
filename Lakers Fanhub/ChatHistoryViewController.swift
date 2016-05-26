//
//  ChatHistoryViewController.swift
//  Lakers Fanhub
//
//  Created by Li Yin on 5/23/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit
import CoreData
import MultipeerConnectivity

class ChatHistoryViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var defaults = NSUserDefaults.standardUserDefaults()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ConvenientView.sharedInstance().setLightNaviBar(self)
        navigationItem.title = "Chat Record"
        
        //Perform CoreData fetch
        fetchedRequestController.delegate = self
        do{
            try fetchedRequestController.performFetch()
        } catch {print(error)}
        
        tableView.tableFooterView = UIView(frame: CGRectZero)
        
        let clearAllButton = UIBarButtonItem(title: "Delete All", style: .Plain, target: self, action: #selector(ChatHistoryViewController.deleteAllButtonTouched))
        navigationItem.rightBarButtonItem = clearAllButton
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatHistoryViewController.handleLostConnection(_:)), name: "lostConnectionWithPeer", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatHistoryViewController.handleSuccessConnection(_:)), name: "connectedWithPeer", object: nil)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedRequestController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let storedPeer = fetchedRequestController.objectAtIndexPath(indexPath) as! ChatPeer
        let cell = tableView.dequeueReusableCellWithIdentifier("storedPeerCell") as! PeerCell
        cell.historyPeer.text = storedPeer.peerName
        cell.historyPeer.textColor = UIColor.darkGrayColor()
        cell.historyPeerLastChatTime.text = String(storedPeer.lastChatTime)
        
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .ShortStyle
        cell.historyPeerLastChatTime.text = "Last connected@  " + formatter.stringFromDate(storedPeer.lastChatTime)
        cell.historyPeerLastChatTime.textColor = UIColor.lightGrayColor()
        
        //Check whether this peer is currently connected
        if appDelegate.mcManager.connectedPeers.containsObject(storedPeer.peerID){
            cell.historyPeer.textColor = ConvenientData().lakersGoldColor
        }
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedPeer = fetchedRequestController.objectAtIndexPath(indexPath) as! ChatPeer
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        //Reset unread message count for this peerID
        defaults.setValue(nil, forKey: selectedPeer.peerID.displayName)
        
        //Prepare and present the ChatViewController
        let controller = storyboard?.instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
        controller.chatPeer = selectedPeer
        if appDelegate.mcManager.connectedPeers.containsObject(selectedPeer.peerID){
            controller.readOnly = false
        } else {
            controller.readOnly = true
        }
        navigationController?.pushViewController(controller, animated: true)
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle{
        case .Delete:
            let peerToDelete = fetchedRequestController.objectAtIndexPath(indexPath) as! ChatPeer
            //If this peer is currently conntected, first disconnect it
            if appDelegate.mcManager.connectedPeers.containsObject(peerToDelete.peerID){
                ConvenientView.sharedInstance().showAlertView("Deleteing active Chat!", message: "This Chat record is currently active, please first disconnect it and then delete the chat record", hostView: self)
            } else {
                sharedContext.deleteObject(peerToDelete)
                CoreDataStackManager.sharedInstance().saveContext()
            }
        default: break
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50.0
    }
    
    //Button action
    func deleteAllButtonTouched(){
        let allStoredPeers = fetchedRequestController.fetchedObjects as! [ChatPeer]
        var foundActiveChat = false
        for peer in allStoredPeers{
            //Only delete the unactive chat record
            if !appDelegate.mcManager.connectedPeers.containsObject(peer.peerID){
                sharedContext.deleteObject(peer)
            } else {
                foundActiveChat = true
            }
        }
        CoreDataStackManager.sharedInstance().saveContext()
        
        if foundActiveChat{
            ConvenientView.sharedInstance().showAlertView("Active Chat!", message: "Active Chat record(gold title) will not be deleted, please first disconnect it", hostView: self)
        }
    }
    
    //Reaction function used for lostConnection notification
    func handleLostConnection(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue()){
            self.tableView.reloadData()
        }
    }
    
    //Reaction function used for successConnection notification
    func handleSuccessConnection(notification: NSNotification){
        dispatch_async(dispatch_get_main_queue()){
            self.tableView.reloadData()
        }
    }
    
    /*** CoreData Implementation ***/
    
    //Set lazy variable for CoreData
    lazy var sharedContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    //Convenient function for later use, enable real-time fetch with predicate
    lazy var fetchedRequestController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "ChatPeer")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastChatTime", ascending: false)]
        let fetchedRequestController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedRequestController
    }()
    
    //implemente FetchedResultController Delegate Method
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
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
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType,newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            break
        case .Move:
            break
        }
    }
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
}
