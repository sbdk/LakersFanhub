//
//  DailyMatchWebViewController.swift
//  Lakers Fanhub
//
//  Created by Li Yin on 4/12/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import UIKit
import WebKit
import MBProgressHUD

class DailyMatchViewController: UIViewController, WKNavigationDelegate {
    
    var webView: WKWebView!
    var loadingHUD: MBProgressHUD!
    
    @IBOutlet weak var homeButton: UIBarButtonItem!
    @IBOutlet weak var reloadButton: UIBarButtonItem!
    @IBOutlet weak var backwardButton: UIBarButtonItem!
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    
    required init(coder aDecoder: NSCoder) {
        self.webView = WKWebView(frame: CGRectZero)
        super.init(coder: aDecoder)!
        webView.navigationDelegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        ConvenientView.sharedInstance().setLightNaviBar(self)
        if Reachability.isConnectedToNetwork() {
            homeButton.enabled = true
            reloadButton.enabled = true
        } else {
            homeButton.enabled = false
            reloadButton.enabled = false
            backwardButton.enabled = false
            forwardButton.enabled = false
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = ConvenientData().lakersPurpleColor
        
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        let height = NSLayoutConstraint(item: webView, attribute: .Height, relatedBy: .Equal, toItem: view, attribute: .Height, multiplier: 1, constant: 0)
        let width = NSLayoutConstraint(item: webView, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1, constant: 0)
        view.addConstraints([height, width])
        webView.addObserver(self, forKeyPath: "loading", options: .New, context: nil)
        
        //Config loadingHUD
        loadingHUD = MBProgressHUD()
        loadingHUD.opacity = 0.6
        loadingHUD.labelText = "Loading..."
        webView.addSubview(loadingHUD)
        
        //Check whether user have internet connection and config webView accordingly
        if Reachability.isConnectedToNetwork(){
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)){
                let url = NSURL(string: "http://espn.go.com/nba/scoreboard")
                let request = NSURLRequest(URL:url!)
                self.webView.loadRequest(request)
            }
            
            dispatch_async(dispatch_get_main_queue()){
                self.loadingHUD.show(true)
                self.backwardButton.enabled = false
                self.forwardButton.enabled = false
            }
            
        } else {
            dispatch_async(dispatch_get_main_queue()){
                self.backwardButton.enabled = false
                self.forwardButton.enabled = false
                ConvenientView.sharedInstance().showNoConnectionAlertView(self)
            }
        }
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        ConvenientView.sharedInstance().showAlertView("Error", message: error.localizedDescription, hostView: self)
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: ((WKNavigationActionPolicy) -> Void)) {
        decisionHandler(WKNavigationActionPolicy.Allow)
    }
    
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if Reachability.isConnectedToNetwork(){
            dispatch_async(dispatch_get_main_queue()){
                self.loadingHUD.show(true)
            }
        }
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        loadingHUD.hide(true)
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        ConvenientView.sharedInstance().showAlertView("Error", message: error.localizedDescription, hostView: self)
    }

    @IBAction func reloadPage(sender: UIBarButtonItem) {
        if Reachability.isConnectedToNetwork(){
            
            if webView.URL != nil{
                let request = NSURLRequest(URL:webView.URL!)
                webView.loadRequest(request)
            } else {
                //If webpage has not loaded homepage yet, present the alertView
                dispatch_async(dispatch_get_main_queue()){
                    ConvenientView.sharedInstance().showAlertView("No webpage available", message: "Please try the home button to load homepage", hostView: self)
                }
            }
        } else {
            dispatch_async(dispatch_get_main_queue()){
                ConvenientView.sharedInstance().showNoConnectionAlertView(self)
            }
        }
    }
    
    @IBAction func backward(sender: UIBarButtonItem) {
        if Reachability.isConnectedToNetwork(){
            dispatch_async(dispatch_get_main_queue()){
                self.webView.goBack()
            }
        }
    }
    
    
    @IBAction func forward(sender: UIBarButtonItem) {
        if Reachability.isConnectedToNetwork(){
            dispatch_async(dispatch_get_main_queue()){
                self.webView.goForward()
            }
        }
    }
    
    @IBAction func homeButtonTouched(sender: UIBarButtonItem) {
        if Reachability.isConnectedToNetwork(){
            let url = NSURL(string: "http://espn.go.com/nba/scoreboard")
            let request = NSURLRequest(URL: url!)
            webView.loadRequest(request)
        } else {
            dispatch_async(dispatch_get_main_queue()){
                ConvenientView.sharedInstance().showNoConnectionAlertView(self)
            }
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "loading"{
            backwardButton.enabled = webView.canGoBack
            forwardButton.enabled = webView.canGoForward
        }
    }
}
