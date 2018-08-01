//
//  ViewController.swift
//  virtualTurist
//
//  Created by Sergio Costa on 22/07/18.
//  Copyright © 2018 Sergio Costa. All rights reserved.
//

import UIKit
import MapKit
import CoreData

/**
 * This view controller demonstrates the objects involved in displaying pins on a map.
 *
 * The map is a MKMapView.
 * The pins are represented by MKPointAnnotation instances.
 *
 * The view controller conforms to the MKMapViewDelegate so that it can receive a method
 * invocation when a pin annotation is tapped. It accomplishes this using two delegate
 * methods: one to put a small "info" button on the right side of each pin, and one to
 * respond when the "info" button is tapped.
 */

class MapViewController: UIViewController{
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController = DataController.sharedInstance
    var pins: [Pin] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.activityIndicator(isBusy: true)
        mapView.delegate = self
        fetchPins()
        insertFetchedPinsOnMap(pins)
        self.view.activityIndicator(isBusy: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configGestureRecognizer()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mapToAlbum"{
            if let vcAlbum = segue.destination as? AlbumViewController{
                if let customPin = sender as? CustomMapPin{
                    vcAlbum.mapPin = customPin
                }
            }
        }
    }
}

// MARK:- UIGestureRecognizerDelegate
extension MapViewController: UIGestureRecognizerDelegate{
    
    func configGestureRecognizer(){
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action:#selector(longPress))
        gestureRecognizer.delegate = self
        gestureRecognizer.minimumPressDuration = 1.0
        
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc func longPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began{
            let location = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(location,toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            getFormatedAddressName(location: annotation.coordinate, completionHandler: { (formatedName) in
                if let name = formatedName{
                    if let persistedPin = self.addPin(name: name, lon: coordinate.longitude.description, lat: coordinate.latitude.description){
                        self.mapView.addAnnotation(self.pinToMapAnnotation(persistedPin))
                    }
                }
            })
        }
    }
}

// MARK:- CoreData
extension MapViewController{
    
    func fetchPins() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            pins = try dataController.viewContext.fetch(fetchRequest)
            print("performed Pin fetch")
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func addPin(name: String, lon: String, lat: String) -> Pin? {
        let pin = Pin(context: dataController.viewContext)
        pin.name = name
        pin.creationDate = Date()
        pin.latitude = lat
        pin.longitude = lon
        
        do{
            try dataController.viewContext.save()
            return pin
        }catch{
            showAlert("Error", message: "Pin cound not be saved: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK:- MapKit
extension MapViewController{
    
    func insertFetchedPinsOnMap(_ pins: [Pin]) {
        DispatchQueue.main.async {
            self.mapView.removeAnnotations(self.mapView.annotations)
        }
        var annotations = [MKPointAnnotation]()
        for pin in pins {
            annotations.append(pinToMapAnnotation(pin))
        }
        DispatchQueue.main.async {
            self.mapView.addAnnotations(annotations)
        }
    }
    
    func pinToMapAnnotation(_ pin: Pin) -> CustomMapPin{
        var coordinate : CLLocationCoordinate2D? = nil
        // Notice that the float values are being used to create CLLocationDegree values.
        // This is a version of the Double type.
        if let lat = pin.latitude{
            if let long = pin.longitude{
                // The lat and long are used to create a CLLocationCoordinates2D instance.
                coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(lat)!, longitude: CLLocationDegrees(long)!)
            }
        }
        
        // Here we create the annotation and set its coordiate, title, and subtitle properties
        let annotation = CustomMapPin()
        if let coord = coordinate{
            annotation.coordinate = coord
        }
        if let name = pin.name{
            annotation.title = name
        }
        if let createdDate = pin.creationDate{
            let df = DateFormatter()
            df.dateStyle = .medium
            annotation.subtitle = df.string(from: createdDate)
        }
        annotation.pinID = pin.objectID
        return annotation
    }
    
    func getFormatedAddressName(location:  CLLocationCoordinate2D, completionHandler: @escaping (_ formatedAddressName: String?)-> Void ){
        // Add below code to get address for touch coordinates.
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(CLLocation.init(latitude: location.latitude, longitude: location.longitude), completionHandler: { (placemarks, error) -> Void in
            
            // Place details
            var placeMark: CLPlacemark!
            placeMark = placemarks?[0]
            
            // Location name
            let formatedName = "\(placeMark.locality ?? "") \(placeMark.administrativeArea ?? "") \(placeMark.country ?? "")"
            
            completionHandler(formatedName)
        })
    }
}

// MARK:- MKMapViewDelegate
extension MapViewController : MKMapViewDelegate {
    
    // Here we create a view with a "right callout accessory view". You might choose to look into other
    // decoration alternatives. Notice the similarity between this method and the cellForRowAtIndexPath
    // method in TableViewDataSource.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = #colorLiteral(red: 0.1321616769, green: 0.6392914653, blue: 0.8661773801, alpha: 1)
            pinView!.animatesDrop = true
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    // This delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews subtitle property.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            self.performSegue(withIdentifier: "mapToAlbum", sender: view.annotation)
        }
    }
}
