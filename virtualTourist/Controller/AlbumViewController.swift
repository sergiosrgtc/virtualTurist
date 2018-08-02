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
    @IBOutlet weak var tableView: UITableView!
    
    var dataController = DataController.sharedInstance
    var pin: Pin!
    var mapPin: CustomMapPin!
    var album: Album?
    var fetchedResultsController:NSFetchedResultsController<Album>!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.view.activityIndicator(isBusy: true)
        
        do{
            try pin = dataController.viewContext.existingObject(with: mapPin.pinID) as! Pin
        }catch{
            showAlert("Error", message: "Pin could not be loaded: \(error.localizedDescription)")
        }
        updateMapWithCoordinate(lat: pin.latitude!, long: pin.longitude!)
        self.view.activityIndicator(isBusy: false)
        if pin.pint_album?.count == 0 {
            createAlbum()
            setupFetchedResultsController()
        }
        self.view.activityIndicator(isBusy: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
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
    
    @IBAction func createNewAlbum(_ sender: Any) {
        createAlbum()
        setupFetchedResultsController()
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "albumToPictures"{
            if let vcCollection = segue.destination as? CollectionPicturesViewController{
                vcCollection.album = sender as? Album
            }
        }
    }
}

// MARK: - Core Data
extension AlbumViewController: NSFetchedResultsControllerDelegate{
    func createAlbum(){
        let album = Album(context: self.dataController.viewContext)
        album.name = "First Album"
        album.creationDate = Date()
        album.page = 1
        album.album_pin = pin
        try? dataController.viewContext.save()
    }
    
    func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Album> = Album.fetchRequest()
        let predicate = NSPredicate(format: "album_pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
            break
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            break
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert:
            tableView.insertSections(indexSet, with: .fade)
        case .delete:
            tableView.deleteSections(indexSet, with: .fade)
        case .update, .move:
            fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}

// MARK: - Table view data source
extension AlbumViewController: UITableViewDataSource, UITableViewDelegate{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "albumCell", for: indexPath)

        let album = fetchedResultsController.object(at: indexPath)
        
        // Configure cell
        cell.textLabel?.text = album.name

        if let creationDate = album.creationDate {
            let df = DateFormatter.localizedString(from: creationDate, dateStyle: .full, timeStyle: .medium)
            cell.detailTextLabel?.text = df
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let album = fetchedResultsController.object(at: indexPath)
        performSegue(withIdentifier: "albumToPictures", sender: album)
    }
}
