

import UIKit
import MapKit
import CoreLocation

class Event: NSObject, MKAnnotation {
    let title: String?
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    let eventObject:PFObject
    //    var locationManager: LocationManager!
    //    let geoCoder = CLGeocoder()
    //    let tempPlace: CLPlacemark
    //
    
    init(title: String, coordinate:CLLocationCoordinate2D, locationName: String, pfEventObject: PFObject) {
        //        locationManager = LocationManager.sharedInstance
        self.title = title
        self.locationName = locationName
        self.coordinate = coordinate
        self.eventObject = pfEventObject
        
        super.init()
    }
    
    
    var subtitle: String? {
        return locationName
    }
}
