//
//  ChatMessageTableCell.swift
//  Lakers Fanhub
//
//  Created by Li Yin on 5/10/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit

class ChatMessageTableCell: UITableViewCell {
    @IBOutlet weak var receivedMessageView: UITextView!

    @IBOutlet weak var receivedMessageViewWidth: NSLayoutConstraint!
    
    @IBOutlet weak var sentMessageView: UITextView!

    @IBOutlet weak var sentMessageViewWidth: NSLayoutConstraint!

}
