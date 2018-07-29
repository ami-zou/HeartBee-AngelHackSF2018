//
//  MapViewController.swift
//  HeartBee
//
//  Created by Ami Zou on 7/29/18.
//  Copyright © 2018 AngelHackSF18. All rights reserved.
//

import UIKit
import HyperTrackCore
import CoreLocation
import MapKit

class MapViewController: UIViewController, LocationUpdateDelegate, MKMapViewDelegate {
   
    @IBOutlet weak var HeaderImageView: UIImageView!
    
    @IBOutlet weak var mapView: MKMapView!
    
    var area: NSMutableArray = NSMutableArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        HyperTrackCore.setLocationUpdatesDelegate(self)
        mapView.showsUserLocation = true
        mapView.delegate = self

        createPolyline()
        // Do any additional setup after loading the view.
        
       // let image = UIImage(named: "mobile-nav.png")
      //  HeaderImageView = UIImageView(image: image!)
        //HeaderImageView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        //myView.addSubview(imageView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func locationUpdates(_ locations: [CLLocation]) {
        for location in locations{
            area.add(location.coordinate)
            centerMapOnLocation(location: location)
        }
        
        
        // show all the locations on the map
    }
    
    func createPolyline(){
        let locations = [
            CLLocationCoordinate2D(latitude: 37.773417, longitude: -122.415864),
            CLLocationCoordinate2D(latitude: 37.774359, longitude: -122.414895),
            CLLocationCoordinate2D(latitude: 37.775172, longitude: -122.416221),
            CLLocationCoordinate2D(latitude: 37.776350, longitude: -122.416221),
            CLLocationCoordinate2D(latitude: 37.777516, longitude: -122.416028),
        ]
        
        let polyLine = MKPolyline(coordinates: locations, count: locations.count)
        
        mapView.add(polyLine)
    }
    
    
    func centerMapOnLocation(location: CLLocation)
    {
        let regionRadius: CLLocationDistance = 200
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer
    {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        polylineRenderer.strokeColor = UIColor.red
        polylineRenderer.lineWidth = 5.0
        return polylineRenderer
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
