//
//  ViewController.swift
//  Lakers Fanhub
//
//  Created by Li Yin on 4/4/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit

class ConvenientView: NSObject {
    
    class func sharedInstance() -> ConvenientView {
        struct Singleton {
            static var sharedInstance = ConvenientView()
        }
        return Singleton.sharedInstance
    }
    
    func showAlertView(title: String, message: String, hostView: UIViewController){
        
        let controller = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil)
        controller.addAction(okAction)
        hostView.presentViewController(controller, animated: true, completion: nil)
    }
    
    

}

