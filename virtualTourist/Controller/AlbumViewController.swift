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
    @IBOutlet weak var collectionView: UICollectionView!
    
    var dataController = DataController.sharedInstance
    var pin: Pin!
    var mapPin: CustomMapPin!
    var album: Album?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        self.view.activityIndicator(isBusy: true)
        
        setUpCollectionViewLayout()
        
        do{
            try pin = dataController.viewContext.existingObject(with: mapPin.pinID) as! Pin
        }catch{
            showAlert("Error", message: "Pin could not be loaded: \(error.localizedDescription)")
        }
        updateMapWithCoordinate(lat: pin.latitude!, long: pin.longitude!)
        if pin.pint_album?.count == 0 {
            getImagesFromFlickr()
        }else{
            album = pin.pint_album?.allObjects.first as? Album
            self.view.activityIndicator(isBusy: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }
    
    func getImagesFromFlickr(){
        FlickrApi.SharedInstance.searchPicturesBy(lat: pin.latitude!, lon: pin.longitude!) { (flickrPics) in
            if let photoAlbum = flickrPics.photoAlbum{
                let album = Album(context: self.dataController.viewContext)
                album.name = "MyAlbum"
                album.creationDate = Date()
                album.page = Int32(photoAlbum.page!)
                self.pin.addToPint_album(album)
                var index = 0
                if let photosArray = photoAlbum.photo{
                    for flickPhoto in photosArray{
                        index = index + 1
                        let photo = Photo(context: self.dataController.viewContext)
                        photo.name = flickPhoto.title!
                        photo.creationDate = Date()
                        photo.url = flickPhoto.urlM!
                        if let imageData = try? Data(contentsOf: URL(string: photo.url!)!) {
                           photo.image = imageData
                        }
                        album.addToAlbum_photo(photo)
                        if index == 15 {
                            break
                        }
                    }
                }
                do{
                    try self.dataController.viewContext.save()
                }catch{
                    self.showAlert("Error", message: "Pin cound not be saved: \(error.localizedDescription)")
                }
                self.album = album
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.view.activityIndicator(isBusy: false)
                }
            }
        }
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

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "albumToPic"{
            if let vcPhoto = segue.destination as? PhotoViewController{
                vcPhoto.photo = sender as? Photo
            }
        }
    }
 

}

// MARK: - UICollectionView
extension AlbumViewController : UICollectionViewDelegate, UICollectionViewDataSource{
   
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return album?.album_photo?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellPic", for: indexPath) as! ImageCollectionViewCell
        cell.activityIndicator(isBusy: true)
        let photo = album?.album_photo?.allObjects[indexPath.row] as! Photo
        if let image = UIImage.init(data: photo.image!) {
            cell.image.image = image
        }
        cell.activityIndicator(isBusy: false)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photo = album?.album_photo?.allObjects[indexPath.row] as! Photo
        performSegue(withIdentifier: "albumToPic", sender: photo)
    }
    
    func setUpCollectionViewLayout(){
        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width - 20
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 5, bottom: 10, right: 5)
        layout.itemSize = CGSize(width: screenWidth/3, height: screenWidth/3)
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 5
        collectionView!.collectionViewLayout = layout
    }
}
