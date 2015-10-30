//
//  nearMeTableViewController.swift
//  SampleBroadcaster-Swift
//
//  Created by Patrick O'Grady on 9/9/15.
//  Copyright © 2015 videocore. All rights reserved.
//

import UIKit
import CoreLocation

class nearMeTableViewController: UITableViewController, CLLocationManagerDelegate {

    var events:NSMutableArray = NSMutableArray()
    
    var eventsRetrieved = NSMutableArray()
    
    var selectedEvent:PFObject!
    
    var locationManager:CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barStyle = UIBarStyle.BlackTranslucent
        
        tableView.registerNib(UINib(nibName: "eventsCell", bundle: nil), forCellReuseIdentifier: "eventsCell")
        
        tableView.rowHeight = 380
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        var mostRecentLocation = locations[0]
        
        var query = PFQuery(className: "events")
        query.orderByDescending("views")
        var currentLocation = PFGeoPoint(latitude: mostRecentLocation.coordinate.latitude, longitude: mostRecentLocation.coordinate.longitude)
        query.whereKey("location", nearGeoPoint: currentLocation, withinMiles: 20.0)
        query.findObjectsInBackground().continueWithBlock({ (task: BFTask!) -> AnyObject! in
            if(task.result != nil) {
                self.events.removeAllObjects()
                print(task.result)
                self.events.addObjectsFromArray(task.result as! [AnyObject])
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
            })
            return task
        })
        
        var currentUser = PFUser.currentUser()!
        currentUser["recentLocation"] = currentLocation
        currentUser.saveInBackground()
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.events.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("eventsCell", forIndexPath: indexPath) as! eventsTableViewCell
        
        let object = self.events.objectAtIndex(indexPath.row) as! PFObject
        
        let currentLocation = PFUser.currentUser()!["recentLocation"] as! PFGeoPoint
        
        let location = object["location"] as! PFGeoPoint
        
        var event = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        var user = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        
        cell.distanceTitle.text = "Distance Away: " + String(event.distanceFromLocation(user)/1600) + " miles"
        
        //var object = self.events.objectAtIndex(indexPath.row) as! PFObject
        cell.eventTitle.text = " " + (object["name"] as! String) + " "
        
        cell.eventTitle.numberOfLines = 0
        cell.eventTitle.sizeToFit()
        
        downloadImage(NSURL(string: object["image"] as! String)!, myImageView: cell.eventImage)
        
        var views = object["views"] as! Int
        
        cell.viewsText.text = " Views: " + String(views) + "  "
        
        

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.selectedEvent = self.events.objectAtIndex(indexPath.row) as! PFObject
//        self.performSegueWithIdentifier("viewFeeds", sender: nil)
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
//        if(segue.identifier == "viewFeeds") {
//            var destination = segue.destinationViewController as! feedsTabViewController
//            destination.eventObject = selectedEvent
////            destination.eventObjectKey = selectedEventKey
//        }
        
    }

}
