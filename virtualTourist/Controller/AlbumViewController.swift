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
            createAlbum(name: "My First Album")
            setupFetchedResultsController()
        }
        self.view.activityIndicator(isBusy: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.title = pin.name ?? "My Pin"

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
    
    func presentDeletePinAlert() {
        let alert = UIAlertController(title: "Delete Pin", message: "Do you want to delete this Pin and all Albums and Photos?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: deleteHandler))
        present(alert, animated: true, completion: nil)
    }
    
    func deleteHandler(alertAction: UIAlertAction) {
        deletePin()
    }
    
    func presentNewAlbumAlert() {
        let alert = UIAlertController(title: "New Album", message: "Enter a name for this album", preferredStyle: .alert)
        
        // Create actions
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] action in
            if let name = alert.textFields?.first?.text {
                self?.createAlbum(name: name)
            }
        }
        saveAction.isEnabled = false
        
        // Add a text field
        alert.addTextField { textField in
            textField.placeholder = "Name"
            NotificationCenter.default.addObserver(forName: .UITextFieldTextDidChange, object: textField, queue: .main) { notif in
                if let text = textField.text, !text.isEmpty {
                    saveAction.isEnabled = true
                } else {
                    saveAction.isEnabled = false
                }
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - IBAction
    @IBAction func createNewAlbum(_ sender: Any) {
        presentNewAlbumAlert()
        setupFetchedResultsController()
    }
    
    @IBAction func deletePin(_ sender: Any) {
        presentDeletePinAlert()
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
    func createAlbum(name: String){
        let album = Album(context: self.dataController.viewContext)
        album.name = name
        album.creationDate = Date()
        album.page = Int32(Double(pin.pint_album!.count / 9) + 1)
        if let lastAlbum = getLatestAlbum(){
            if lastAlbum.end == Constants.Flickr.MaxItemsPerPage{
                album.begin = 1
                album.end = Int32(Constants.Flickr.StandardPage)
            }else{
                album.begin =  lastAlbum.end + 1
                let end = lastAlbum.end + Int32(Constants.Flickr.StandardPage)
                end >= Constants.Flickr.MaxItemsPerPage ?  (album.end = Int32(Constants.Flickr.MaxItemsPerPage)) : (album.end = end)
            }
        }else{
            album.begin = 1
            album.end = Int32(Constants.Flickr.StandardPage)
        }
        print("\(album.page) \(album.begin) - \(album.end) ")
        album.album_pin = pin
        try? dataController.viewContext.save()
    }
    
    func deleteAlbum(at indexPath: IndexPath) {
        let albumToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(albumToDelete)
        try? dataController.viewContext.save()
    }
    func deletePin() {
        dataController.viewContext.delete(pin)
        try? dataController.viewContext.save()
        self.navigationController?.popViewController(animated: true)
    }

    // MARK: - NSFetchedResultsControllerDelegate
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
    
    func getLatestAlbum() -> Album? {
        let fetchRequest:NSFetchRequest<Album> = Album.fetchRequest()
        let predicate = NSPredicate(format: "album_pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            let result = try self.dataController.viewContext.fetch(fetchRequest)
            return result.first
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
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete: deleteAlbum(at: indexPath)
        default: () // Unsupported
        }
    }
}
