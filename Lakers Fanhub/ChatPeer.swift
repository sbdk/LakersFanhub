//
//  ChatHistory.swift
//  Lakers Fanhub
//
//  Created by Li Yin on 5/23/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MultipeerConnectivity

class ChatPeer: NSManagedObject {
    
    @NSManaged var peerID: MCPeerID
    @NSManaged var peerName: String
    @NSManaged var chatMessages: [ChatMessage]?
    @NSManaged var lastChatTime: NSDate
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(newPeerID: MCPeerID, messagesArray: NSMutableArray?, context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("ChatPeer", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        peerID = newPeerID
        peerName = newPeerID.displayName
        lastChatTime = NSDate()
    }
    
}