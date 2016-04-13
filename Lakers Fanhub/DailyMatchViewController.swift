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
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)){
            let url = NSURL(string: "http://espn.go.com/nba/scoreboard")
            let request = NSURLRequest(URL:url!)
            self.webView.loadRequest(request)
        }
        loadingHUD = MBProgressHUD()
        loadingHUD.show(true)
        loadingHUD.opacity = 0.6
        loadingHUD.labelText = "Loading..."
        webView.addSubview(loadingHUD)
        
        backwardButton.enabled = false
        forwardButton.enabled = false
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        ConvenientView.sharedInstance().showAlertView("Error", message: error.localizedDescription, hostView: self)
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: ((WKNavigationActionPolicy) -> Void)) {
        decisionHandler(WKNavigationActionPolicy.Allow)
    }
    
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadingHUD.show(true)
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        loadingHUD.hide(true)
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        ConvenientView.sharedInstance().showAlertView("Error", message: error.localizedDescription, hostView: self)
    }

    @IBAction func reloadPage(sender: UIBarButtonItem) {
        let request = NSURLRequest(URL:webView.URL!)
        webView.loadRequest(request)
    }
    
    @IBAction func backward(sender: UIBarButtonItem) {
        webView.goBack()
    }
    
    
    @IBAction func forward(sender: UIBarButtonItem) {
        webView.goForward()
    }
    
    @IBAction func homeButtonTouched(sender: UIBarButtonItem) {
        let url = NSURL(string: "http://espn.go.com/nba/scoreboard")
        let request = NSURLRequest(URL: url!)
        webView.loadRequest(request)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "loading"{
            backwardButton.enabled = webView.canGoBack
            forwardButton.enabled = webView.canGoForward
        }
    }
}
