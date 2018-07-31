//
//  AlbumViewController.swift
//  virtualTourist
//
//  Created by Sergio Costa on 30/07/18.
//  Copyright © 2018 Sergio Costa. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class AlbumViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController = DataController.sharedInstance
    var pin: Pin!
    var mapPin: CustomMapPin!

    override func viewDidLoad() {
        super.viewDidLoad()

        do{
            try pin = dataController.viewContext.existingObject(with: mapPin.pinID) as! Pin
        }catch{
            showAlert("Error", message: "Pin could not be loaded: \(error.localizedDescription)")
        }
        updateMapWithCoordinate(lat: pin.latitude!, long: pin.longitude!)
    }
    
    func updateMapWithCoordinate(lat: String, long: String){
        let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(lat)!, longitude: CLLocationDegrees(long)!)
        if var region = mapView?.region {
            region.center = coordinate
            region.span.longitudeDelta = 8.0
            region.span.latitudeDelta = 8.0
            mapView.setRegion(region, animated: true)
            mapView.addAnnotation(mapPin)
            mapView.isZoomEnabled = false
            mapView.isPitchEnabled = false
            mapView.isRotateEnabled = false
            mapView.isScrollEnabled = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
