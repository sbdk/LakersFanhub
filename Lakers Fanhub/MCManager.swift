//
//  MCManager.swift
//  Lakers Fanhub
//
//  Created by Li Yin on 4/14/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import MultipeerConnectivity

protocol MCManagerBrowserDelegate {
    
    func foundPeer()
    
    func lostPeer()

//    func connectedWithPeer(peerID: MCPeerID)
}

protocol MCManagerInvitationDelegate {
    
    func invitationWasReceived(fromPeer: String, invitationHandler:(Bool, MCSession?) -> Void)
}

protocol MCManagerSessionDelegate {
    
    func connectedWithPeer(peerID: MCPeerID)
    
    func connectingWithPeer()
    
    func notConnectedWithPeer()
}

class MCManager: NSObject, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {
    
    var peerID: MCPeerID!
    var session: MCSession!
    var browser: MCNearbyServiceBrowser!
    var advertiser: MCNearbyServiceAdvertiser!
    
    var foundPeers = [MCPeerID]()
//    var invitationHandler: ((Bool, MCSession!)->Void)!
    
    var browserDelegate: MCManagerBrowserDelegate?
    var invitationDelegate: MCManagerInvitationDelegate?
    var sessionDelegate: MCManagerSessionDelegate?
    
//    class func sharedInstance() -> MCManager {
//        struct Singleton {
//            static var sharedInstance = MCManager()
//        }
//        return Singleton.sharedInstance
//    }
    
    override init(){
        super.init()
        peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
        session = MCSession(peer: peerID)
        session.delegate = self
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: "lakers-fanhub")
        browser.delegate = self
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "lakers-fanhub")
        advertiser.delegate = self
    }
    
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        foundPeers.append(peerID)
        browserDelegate?.foundPeer()
    }
    
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        for (index, peer) in foundPeers.enumerate() {
            if peer == peerID {
                foundPeers.removeAtIndex(index)
                break
            }
        }
        browserDelegate?.lostPeer()
    }
    
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        print(error.localizedDescription)
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
        print("received a invitation")
        self.invitationDelegate?.invitationWasReceived(peerID.displayName){(Bool, MCSession) in
            invitationHandler(Bool, MCSession!)
        }
        
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        print(error.localizedDescription)
    }
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        
        switch state {
        case MCSessionState.Connected:
            print("Connected to session: \(session)")
            sessionDelegate?.connectedWithPeer(peerID)
        case MCSessionState.Connecting:
            print("Connecting to session:\(session)")
            sessionDelegate?.connectingWithPeer()
        default:
            sessionDelegate?.notConnectedWithPeer()
            print("did not connect to session: \(session)")
        }   
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
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: "lakers-fanhub")
        browser.delegate = self
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "lakers-fanhub")
        advertiser.delegate = self
    }
}
