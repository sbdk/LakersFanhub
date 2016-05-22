//
//  helpViewController.swift
//  Lakers Fanhub
//
//  Created by Li Yin on 5/19/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit

class HelpViewController: UIViewController {
    
    @IBOutlet weak var blueToothWifiNotice: UILabel!
    
    @IBOutlet weak var disconnectButtonNotice: UILabel!
    
    @IBOutlet weak var chatIDNotice: UILabel!
    
    @IBOutlet weak var endChatButtonNotice: UILabel!
    
    
    override func viewDidLoad() {
        view.backgroundColor = UIColor.whiteColor()
        
        blueToothWifiNotice.sizeToFit()
        disconnectButtonNotice.sizeToFit()
        chatIDNotice.sizeToFit()
        endChatButtonNotice.sizeToFit()
    }

}
