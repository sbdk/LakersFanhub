//
//  MCManager.swift
//  Lakers Fanhub
//
//  Created by Li Yin on 4/14/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import MultipeerConnectivity

class MCManager: NSObject, MCSessionDelegate {
    
    var peerID: MCPeerID! = nil
    var session: MCSession! = nil
    var browser: MCBrowserViewController! = nil
    var advertiser: MCAdvertiserAssistant! = nil
    
    class func sharedInstance() -> MCManager {
        struct Singleton {
            static var sharedInstance = MCManager()
        }
        return Singleton.sharedInstance
    }
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        
        var dict:[String:AnyObject] = ["peerID":peerID, "state": state.rawValue]
        print("state rawValue: \(state.rawValue)")
        NSNotificationCenter.defaultCenter().postNotificationName("MCDidChangeStateNotification", object: nil, userInfo: dict)
        
    }
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        
    }
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func setupPeerAndSessionWithDisplayName(name: String){
        
        peerID = MCPeerID.init(displayName: name)
        session = MCSession.init(peer: peerID)
        session.delegate = self
        
    }
    
    func setupMCBrowser(){
        
        browser = MCBrowserViewController.init(serviceType: "chat-files", session: session)
        
    }
    
    func advertiseSelf(shouldAdvertise: Bool){
        
        if shouldAdvertise {
            advertiser = MCAdvertiserAssistant.init(serviceType: "chat-files", discoveryInfo: nil, session: session)
            advertiser.start()
        } else {
            advertiser.stop()
            advertiser = nil
        }
        
    }
}
