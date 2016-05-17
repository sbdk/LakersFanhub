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
    
    func setLabel(label: UILabel, fontName: String, size: CGFloat, color: UIColor){
        label.font = UIFont(name: fontName, size: size)
        label.textColor = color
    }
    
    func setRoundButton(button: UIButton){
        button.layer.cornerRadius = button.bounds.size.width * 0.5
    }
    
    func setDarkNaviBar(rootViewController: UIViewController){
        let naviBar = rootViewController.navigationController?.navigationBar
        naviBar!.barTintColor = ConvenientData().lakersPurpleColor
        naviBar!.titleTextAttributes = [NSForegroundColorAttributeName: ConvenientData().lakersGoldColor]
        naviBar!.tintColor = ConvenientData().lakersGoldColor
        naviBar!.barStyle = UIBarStyle.Black
        naviBar!.translucent = false
    }
    
    func setLightNaviBar(rootViewController: UIViewController){
        let naviBar = rootViewController.navigationController?.navigationBar
        naviBar!.barTintColor = UIColor.whiteColor()
        naviBar!.titleTextAttributes = [NSForegroundColorAttributeName: ConvenientData().lakersPurpleColor]
        naviBar!.tintColor = ConvenientData().lakersPurpleColor
        naviBar!.barStyle = UIBarStyle.Default
        naviBar!.translucent = false
    }
    
    func enhanceItemUI(button: AnyObject, cornerRadius: CGFloat){
        
        button.layer.shadowColor = UIColor.blackColor().CGColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 3
        button.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        button.layer.cornerRadius = cornerRadius
        
    }
}

