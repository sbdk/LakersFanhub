//
//  NewsDetailViewController.swift
//  Lakers Fanhub
//
//  Created by Li Yin on 4/7/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit
import WebKit
import MBProgressHUD

class NewsDetailViewController: UIViewController, WKNavigationDelegate, UIScrollViewDelegate {
    
    var webView: WKWebView!
    var feedURLString: String = ""
    var progressHUD: MBProgressHUD!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    required init(coder aDecoder: NSCoder) {
        self.webView = WKWebView(frame: CGRectZero)
        super.init(coder: aDecoder)!
        webView.navigationDelegate = self
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "estimatedProgress" {
            
            progressHUD.progress = Float(webView.estimatedProgress)
            if webView.estimatedProgress == 1{
                progressHUD.hide(true)
                shareButton.enabled = true
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.tintColor = ConvenientData().lakersGoldColor
        tabBarController?.tabBar.hidden = true
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        webView.removeObserver(self, forKeyPath: "estimatedProgress")
        tabBarController?.tabBar.hidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        shareButton.enabled = false
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        let height = NSLayoutConstraint(item: webView, attribute: .Height, relatedBy: .Equal, toItem: view, attribute: .Height, multiplier: 1, constant: 0)
        let width = NSLayoutConstraint(item: webView, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1, constant: 0)
        view.addConstraints([height, width])
        
        progressHUD = MBProgressHUD()
        self.view.addSubview(progressHUD)
        progressHUD.mode = MBProgressHUDMode.DeterminateHorizontalBar
        progressHUD.opacity = 0.6
        progressHUD.labelText = "Page loading..."
        progressHUD.show(true)
 
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)){
            let url = NSURL(string:self.feedURLString)
            let request = NSURLRequest(URL:url!)
            self.webView.loadRequest(request)
        }
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
       ConvenientView.sharedInstance().showAlertView("Error", message: error.localizedDescription, hostView: self)
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: ((WKNavigationActionPolicy) -> Void)) {
        decisionHandler(WKNavigationActionPolicy.Allow)
//        if (navigationAction.navigationType == WKNavigationType.LinkActivated && !navigationAction.request.URL!.host!.lowercaseString.hasPrefix("www.hoopsrumors.com")) {
//            UIApplication.sharedApplication().openURL(navigationAction.request.URL!)
//            decisionHandler(WKNavigationActionPolicy.Cancel)
//        } else {
//            decisionHandler(WKNavigationActionPolicy.Allow)
//        }
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        progressHUD.progress = 0.0
        feedURLString = String(webView.URL!)
    }
    
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressHUD.show(true)
        shareButton.enabled = false
    }
    
    @IBAction func shareButtonTouched(sender: AnyObject) {
        let shareViewController = UIActivityViewController(activityItems: [feedURLString], applicationActivities: nil)
        shareViewController.completionWithItemsHandler = {
            activity, completed, items, error in
            if completed {
                let actionHUD = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
                actionHUD.mode = MBProgressHUDMode.CustomView
                let image = UIImage(named: "CheckMark")
                actionHUD.customView = UIImageView.init(image: image)
                actionHUD.square = true
                actionHUD.labelText = "Done"
                actionHUD.hide(true, afterDelay: 2.0)
            }
        }
        presentViewController(shareViewController, animated: true, completion: nil)
    }
}
