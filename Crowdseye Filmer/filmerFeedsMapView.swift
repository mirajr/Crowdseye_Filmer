//
//  feedsMapViewController.swift
//  SampleBroadcaster-Swift
//
//  Created by Patrick O'Grady on 9/10/15.
//  Copyright © 2015 videocore. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class filmerFeedsMapView: UIViewController, MKMapViewDelegate {
    
    var eventObject:PFObject!
    
    var selectedFeed: PFObject!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barStyle = UIBarStyle.BlackTranslucent
        
        self.feedsMapView.delegate = self
        self.feedsMapView.showsUserLocation = true
        
        var feedsTabBar = self.tabBarController as! feedsTabViewController
        
        self.eventObject = feedsTabBar.eventObject
        print(self.eventObject)
        
        var query = PFQuery(className: "feeds")
        query.orderByDescending("views")
        query.whereKey("event", equalTo: self.eventObject.objectId!)
        
        
        query.findObjectsInBackgroundWithBlock { (results:[PFObject]?, error: NSError?) -> Void in
            if(error == nil) {
                print(results)
                for eventObj in results! {
                    var object = eventObj as! PFObject
                    var name = object["name"] as! String
                    var coords = object["location"] as! PFGeoPoint
                    var views = object["views"] as! Int
                    self.feedsMapView.addAnnotation(Event(title: name, coordinate: CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude), locationName: "Views: \(views)", pfEventObject: object))
                }
                
            }
            
            self.feedsMapView.showAnnotations(self.feedsMapView.annotations, animated: true)
        }
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    @IBOutlet weak var feedsMapView: MKMapView!
    @IBAction func dismissView(sender: UIBarButtonItem) {
        self.tabBarController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView! {
        if(annotation.isKindOfClass(MKUserLocation)) {
            return nil
        }
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier("eventLocations")
        let eventMarker = UIImage(named: "EventAnnotation")
        let arrow   = UIButton(type: UIButtonType.System)
        if let arrowImage = UIImage(named: "Arrow") {
            arrow.setImage(arrowImage, forState: .Normal)
            arrow.frame = CGRectMake(arrowImage.size.width, arrowImage.size.height, arrowImage.size.width, arrowImage.size.height)
        }
        //NEED TO ADD TARGET TO THE BUTTON SO THAT USER IS BROUGHT TO FEEDS PAGE WHEN CLICKED
        
        let pfAnnotation = annotation as! Event
        
        var obj = pfAnnotation.eventObject as! PFObject
        var views = obj["views"] as! Int
        
        //Scaling the image code
        let cgImage = UIImage(named: "EventAnnotation")!.CGImage
        let width = CGImageGetWidth(cgImage) / 5
        let height = CGImageGetHeight(cgImage) / 5
        let bitsPerComponent = CGImageGetBitsPerComponent(cgImage)
        let bytesPerRow = CGImageGetBytesPerRow(cgImage)
        let colorSpace = CGImageGetColorSpace(cgImage)
        let bitmapInfo = CGImageGetBitmapInfo(cgImage)
        let context = CGBitmapContextCreate(nil, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo.rawValue)
        
        CGContextSetInterpolationQuality(context, CGInterpolationQuality.High)
        CGContextDrawImage(context, CGRect(origin: CGPointZero, size: CGSize(width: CGFloat(width), height: CGFloat(height))), cgImage)
        let scaledImage = CGBitmapContextCreateImage(context)
        
        
        
        if( pinView == nil ) {
            pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: "eventLocations")
            pinView!.image = UIImage(CGImage: scaledImage!)
            pinView!.canShowCallout = true
            //Adding a custom button to the right accessory view
            pinView!.rightCalloutAccessoryView = arrow
            
        }
        return pinView
    }
    
    //View more arrow touched
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let object = view.annotation! as! Event
        self.selectedFeed = object.eventObject
        self.performSegueWithIdentifier("viewFeed", sender: nil)
        
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if(segue.identifier == "viewFeed") {
            var destination = segue.destinationViewController as! filmerWatchFeed
            destination.feedObject = self.selectedFeed as! PFObject
            destination.eventObject = self.eventObject
        }
        
    }
    
    
}
