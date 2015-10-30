//
//  watchFeedViewController.swift
//  Crowdseye News
//
//  Created by Patrick O'Grady on 10/30/15.
//  Copyright © 2015 crowdseye. All rights reserved.
//

import UIKit

class filmerWatchFeed: UIViewController {
    
    var feedObject:PFObject!
    
    var eventObject:PFObject! //for incrementing event views
    
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var feedURL:String!
        do {
            try self.feedObject.fetch()
        } catch {
            print("Could not fetch event")
        }
        
        if(feedObject["status"] as! String == "live") {
            feedURL = "https://s3-us-west-1.amazonaws.com/crowdseye/\(feedObject.objectId!)/index.m3u8"
        } else {
            feedURL = "https://s3-us-west-1.amazonaws.com/crowdseye/\(feedObject.objectId!)/vod.m3u8"
            
        }
        
        if(eventObject != nil) {
            feedObject.incrementKey("views")
            feedObject.saveInBackground()
            eventObject.incrementKey("views")
            eventObject.saveInBackground()
        }
        
        let htmlPage = "<!doctype html><html><head><script src=\"//api.peer5.com/peer5.js?id=jyzzb4z56l1c8y62hmdq\"></script><script src=\"video.js\"></script><script src=\"videojs-media-sources.js\"></script><script src=\"//api.peer5.com/peer5.videojs.hls.js\"></script><script src=\"https://ajax.googleapis.com/ajax/libs/jquery/2.1.3/jquery.min.js\"></script><script src=\"js/requestAnimationFrame.js\"></script><script src=\"js/inline-video.js\"></script><style type=\"text/css\">video#player {position: fixed;top: 50%;left: 50%;min-width: 100%;min-height: 100%;width: auto;height: auto;z-index: -100;-webkit-transform: translateX(-50%) translateY(-50%);transform: translateX(-50%) translateY(-50%);}</style></head><body><video id=\"player\" class=\"video-js vjs-default-skin\" controls autoplay playsinline webkit-playsinline><source src=\"\(feedURL)\"/></video><script>var player = videojs('#player');</script></body></html>"
        webView.loadHTMLString(htmlPage, baseURL: nil)
        webView.scrollView.scrollEnabled = false
        webView.scalesPageToFit = true
        webView.allowsInlineMediaPlayback = true
        webView.mediaPlaybackRequiresUserAction = false
        
        
        
    }
    
    @IBAction func closeView(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        self.webView.loadRequest(NSURLRequest(URL: NSURL(string: "http://www.google.com")!))
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
