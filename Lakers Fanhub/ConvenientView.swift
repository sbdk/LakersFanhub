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
    
    let newsTitleTextAttributes = [
        NSStrokeColorAttributeName : UIColor(red: 92/255.0, green: 92/255.0, blue: 92/255.0, alpha: 1.0),
        NSForegroundColorAttributeName: UIColor.whiteColor(),
        NSFontAttributeName :UIFont(name: "Courier", size: 16)!,
        NSStrokeWidthAttributeName : 0
    ]
    
    let newsSubTitleTextAttributes = [
        NSStrokeColorAttributeName : UIColor.blackColor(),
        NSForegroundColorAttributeName: UIColor.whiteColor(),
        NSFontAttributeName :UIFont(name: "Avenir-Light", size: 10)!,
        NSStrokeWidthAttributeName : 0
    ]
    
    
    func setLabel(label: UILabel, fontName: String, size: CGFloat, color: UIColor){
        
        label.font = UIFont(name: fontName, size: size)
        label.textColor = color
        
    }

}

