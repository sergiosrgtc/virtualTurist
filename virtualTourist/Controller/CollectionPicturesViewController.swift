//
//  CollectionPicturesViewController.swift
//  virtualTourist
//
//  Created by Sergio Costa on 01/08/18.
//  Copyright © 2018 Sergio Costa. All rights reserved.
//

import UIKit
import CoreData

class CollectionPicturesViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    
    var dataController = DataController.sharedInstance
    var pin: Pin!
    var mapPin: CustomMapPin!
    var album: Album?
    var downloadCollectionSize = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        self.view.activityIndicator(isBusy: true)

        if (album?.album_photo?.count)! < 1{
            getImagesFromFlickr()
        }else{
            self.view.activityIndicator(isBusy: false)
            downloadCollectionSize = (album?.album_photo?.count)!
        }
        
        setUpCollectionViewLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }
    
    @IBAction func refresh(_ sender: Any) {
        self.view.activityIndicator(isBusy: true)
        deleteAllPhotos()
        getRandomImagesFromFlickr()
    }
    
    func deleteAllPhotos() {
        for photo in (album?.album_photo?.allObjects)! {
            dataController.viewContext.delete(photo as! NSManagedObject)
        }
        try? dataController.viewContext.save()
        downloadCollectionSize = 0
        self.collectionView.reloadData()
    }
    
// MARK: - Flicker API Methods
    func getRandomImagesFromFlickr(){
        FlickrApi.SharedInstance.searchRandomPicturesBy(lat: album!.album_pin!.latitude!, lon: album!.album_pin!.longitude!) { (flickrPics) in
            if let photoAlbum = flickrPics.photoAlbum{
                if let photosArray = photoAlbum.photo{
                    var index = 0
                    self.downloadCollectionSize = photosArray.count >= Constants.Flickr.StandardPage ? Constants.Flickr.StandardPage : photosArray.count
                    DispatchQueue.main.async{
                        self.collectionView.reloadData()
                    }
                    for flickPhoto in photosArray{
                        index = index + 1
                        let photo = Photo(context: self.dataController.viewContext)
                        photo.name = flickPhoto.title!
                        photo.creationDate = Date()
                        photo.url = flickPhoto.urlM!
                        if let imageData = try? Data(contentsOf: URL(string: photo.url!)!) {
                            photo.image = imageData
                        }
                        self.album?.addToAlbum_photo(photo)
                        
                        try? self.dataController.viewContext.save()
                        DispatchQueue.main.async{
                            self.collectionView.reloadData()
                        }
                        if index == Constants.Flickr.StandardPage{
                            break
                        }
                    }
                }
                do{
                    try self.dataController.viewContext.save()
                }catch{
                    self.showAlert("Error", message: "Pin cound not be saved: \(error.localizedDescription)")
                }
                DispatchQueue.main.async {
                    self.view.activityIndicator(isBusy: false)
                    self.collectionView.reloadData()
                }
            }
        }
    }

    func getImagesFromFlickr(){
        FlickrApi.SharedInstance.searchPicturesBy(lat: album!.album_pin!.latitude!, lon: album!.album_pin!.longitude!, withPageNumber: Int(album!.page)) { (flickrPics) in
            if let photoAlbum = flickrPics.photoAlbum{
                if let photosArray = photoAlbum.photo{
                    if photosArray.count > 0{
                        let start = Int(self.album!.begin - 1)
                        var end = Int(self.album!.end - 1)
                        if photosArray.count < end{
                            end = photosArray.count - 1
                        }
                        let rangedPhotos = photosArray[start...end]
                        self.downloadCollectionSize = rangedPhotos.count
                        DispatchQueue.main.async{
                            self.collectionView.reloadData()
                        }
                        for flickPhoto in rangedPhotos{
                            let photo = Photo(context: self.dataController.viewContext)
                            photo.name = flickPhoto.title!
                            photo.creationDate = Date()
                            photo.url = flickPhoto.urlM!
                            if let imageData = try? Data(contentsOf: URL(string: photo.url!)!) {
                                photo.image = imageData
                            }
                            self.album?.addToAlbum_photo(photo)
                            
                            try? self.dataController.viewContext.save()
                            DispatchQueue.main.async{
                                self.collectionView.reloadData()
                            }
                        }
                    }
                }
                do{
                    try self.dataController.viewContext.save()
                }catch{
                    self.showAlert("Error", message: "Pin cound not be saved: \(error.localizedDescription)")
                }
                DispatchQueue.main.async {
                    self.view.activityIndicator(isBusy: false)
                    self.collectionView.reloadData()
                }
            }
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
extension CollectionPicturesViewController : UICollectionViewDelegate, UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return downloadCollectionSize
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellPic", for: indexPath) as! ImageCollectionViewCell
        cell.activityIndicator(isBusy: true)
        if let allObject = album?.album_photo?.allObjects{
            print(allObject.count)
            print(indexPath.row)
            if allObject.count > indexPath.row{
                let photo = album?.album_photo?.allObjects[indexPath.row] as? Photo
                if let pic = photo{
                    if let image = UIImage.init(data: pic.image!) {
                        cell.image.image = image
                    }
                }
            }
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
