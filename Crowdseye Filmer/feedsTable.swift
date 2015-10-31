//
//  feedTableViewController.swift
//  SampleBroadcaster-Swift
//
//  Created by Patrick O'Grady on 9/8/15.
//  Copyright © 2015 videocore. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class feedsTable: UITableViewController {
    
    var eventObject:PFObject!
    
    var feeds: NSMutableArray = NSMutableArray()
    
    var selectedFeed:PFObject!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barStyle = UIBarStyle.BlackTranslucent
        
        var feedsTabBar = self.tabBarController as! feedsTabViewController
        
        self.eventObject = feedsTabBar.eventObject
        
        tableView.registerNib(UINib(nibName: "feedsCell", bundle: nil), forCellReuseIdentifier: "feedsCell")
        
        tableView.rowHeight = 380
        
        var query = PFQuery(className: "feeds")
        query.whereKey("event", equalTo: eventObject.objectId!)
        query.orderByDescending("views")
        
        query.findObjectsInBackground().continueWithBlock({ (task: BFTask!) -> AnyObject! in
            if(task.result != nil) {
                self.feeds.removeAllObjects()
                self.feeds.addObjectsFromArray(task.result as! [AnyObject])
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
            })
            return task
        })
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func returnToEvents(sender: UIBarButtonItem) {
        self.tabBarController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func getDirections(sender: UIBarButtonItem) {
        var location = self.eventObject["location"] as! PFGeoPoint
        var coordinates = CLLocationCoordinate2DMake(location.latitude, location.longitude)
        var placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        var mapItem = MKMapItem(placemark: placemark)
        mapItem.name = self.eventObject["name"] as! String
        mapItem.openInMapsWithLaunchOptions(nil)
    }
    
    @IBAction func goLive(sender: UIBarButtonItem) {
        //must ensure at location?
        
        let currentLocation = PFUser.currentUser()!["recentLocation"] as! PFGeoPoint
        
        let location = self.eventObject["location"] as! PFGeoPoint
        
        var event = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        var user = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        
        if(event.distanceFromLocation(user) > 400) {
            UIAlertView(title: "Error", message: "You must be within 400 meters of the event center to film.", delegate: nil, cancelButtonTitle: "Ok").show()
            return
        }

        
        var kickflip = Kickflip.setupWithAPIKey("test", secret: "test")
        Kickflip.presentBroadcasterFromViewController(self, eventObject: self.eventObject, ready: nil, completion: nil)
    }
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.feeds.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("feedsCell", forIndexPath: indexPath) as! feedsTableViewCell
        
        var object = self.feeds.objectAtIndex(indexPath.row) as! PFObject
        
        cell.feedTitle.text = " " + (object["name"] as! String) + " "
        
        cell.feedTitle.numberOfLines = 0
        cell.feedTitle.sizeToFit()
        
        var views = object["views"] as! Int
        
        cell.feedViews.text = " Views: " + String(views) + "  "
        
        cell.feedAuthor.text = object["author"] as! String
        
        downloadImage(NSURL(string: object["image"] as! String)!, myImageView: cell.feedPreview)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.selectedFeed = self.feeds.objectAtIndex(indexPath.row) as! PFObject
        self.performSegueWithIdentifier("viewFeed", sender: nil)
        
    }
    
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return false if you do not want the specified item to be editable.
    return true
    }
    */
    
    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
    // Delete the row from the data source
    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    } else if editingStyle == .Insert {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
    }
    */
    
    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
    
    }
    */
    
    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return false if you do not want the item to be re-orderable.
    return true
    }
    */
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if(segue.identifier == "viewFeed") {
            var destination = segue.destinationViewController as! filmerWatchFeed
            destination.feedObject = self.selectedFeed
            destination.eventObject = self.eventObject
        }
        
    }
    
    
}
