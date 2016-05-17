//
//  MoreViewController.swift
//  Lakers Fanhub
//
//  Created by Li Yin on 5/16/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit
import MBProgressHUD

class MoreViewController: UIViewController {
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var rateUsButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    var doneHUD: MBProgressHUD!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.hidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backgroundImage = UIImage(named: "LakersFanhubRateUs")
        backgroundImageView.image = backgroundImage
        backgroundImageView.contentMode = .ScaleAspectFill
        
        ConvenientView.sharedInstance().enhanceItemUI(rateUsButton, cornerRadius: 10.0)
        ConvenientView.sharedInstance().enhanceItemUI(shareButton, cornerRadius: 10.0)
        
        doneHUD = MBProgressHUD()
        self.view.addSubview(doneHUD)
        doneHUD.mode = MBProgressHUDMode.CustomView
        let image = UIImage(named: "CheckMark")
        doneHUD.customView = UIImageView.init(image: image)
        doneHUD.square = true
        doneHUD.labelText = "Done"
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.hidden = false
    }
    
    @IBAction func rateUsButtonTouched(sender: AnyObject) {
    }
    
    
    @IBAction func shareButtonTouched(sender: AnyObject) {
        let shareViewController = UIActivityViewController(activityItems: ["haha"], applicationActivities: nil)
        shareViewController.completionWithItemsHandler = {
            activity, completed, items, error in
            if completed {
                self.doneHUD.show(true)
//                let actionHUD = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
//                actionHUD.mode = MBProgressHUDMode.CustomView
//                let image = UIImage(named: "CheckMark")
//                actionHUD.customView = UIImageView.init(image: image)
//                actionHUD.square = true
//                actionHUD.labelText = "Done"
                self.doneHUD.hide(true, afterDelay: 1.0)
            }
        }
        presentViewController(shareViewController, animated: true, completion: nil)
    }

    
}
