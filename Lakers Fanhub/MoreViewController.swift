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

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var rateUsButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    var doneHUD: MBProgressHUD!
    var shareViewController: UIActivityViewController!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.hidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set rateUs image
        let rateImage = UIImage(named: "LakersFanhubRateUs")
        imageView.image = rateImage
        imageView.contentMode = .ScaleAspectFill
        
        //Custom two buttons
        ConvenientView.sharedInstance().enhanceItemUI(rateUsButton, cornerRadius: 10.0)
        ConvenientView.sharedInstance().enhanceItemUI(shareButton, cornerRadius: 10.0)
        
        //Prepare HUDView for share action
        doneHUD = MBProgressHUD()
        doneHUD.mode = MBProgressHUDMode.CustomView
        let image = UIImage(named: "CheckMark")
        doneHUD.customView = UIImageView.init(image: image)
        doneHUD.square = true
        doneHUD.labelText = "Done"
        self.view.addSubview(doneHUD)
        
        shareViewController = UIActivityViewController(activityItems: ["haha"], applicationActivities: nil)
        shareViewController.completionWithItemsHandler = {
            activity, completed, items, error in
            if completed {
                self.doneHUD.show(true)
                self.doneHUD.hide(true, afterDelay: 1.0)
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.hidden = false
    }
    
    @IBAction func rateUsButtonTouched(sender: AnyObject) {
    }
    
    
    @IBAction func shareButtonTouched(sender: AnyObject) {
        
        presentViewController(shareViewController, animated: true, completion: nil)
    }

    
}
