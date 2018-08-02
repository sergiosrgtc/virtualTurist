//
//  CollectionPicturesViewController.swift
//  virtualTourist
//
//  Created by Sergio Costa on 01/08/18.
//  Copyright © 2018 Sergio Costa. All rights reserved.
//

import UIKit

class CollectionPicturesViewController: UIViewController {
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

        if (album?.album_photo?.count)! < 1{
            getImagesFromFlickr()
        }else{
            self.view.activityIndicator(isBusy: false)
        }
        
        setUpCollectionViewLayout()
    }

    func getImagesFromFlickr(){
        FlickrApi.SharedInstance.searchPicturesBy(lat: album!.album_pin!.latitude!, lon: album!.album_pin!.longitude!) { (flickrPics) in
            if let photoAlbum = flickrPics.photoAlbum{
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
                        self.album?.addToAlbum_photo(photo)
                        
                        try? self.dataController.viewContext.save()
                        DispatchQueue.main.async{
                            self.collectionView.reloadData()
                        }
                        if index == 30 {
                            self.view.activityIndicator(isBusy: false)
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
                    self.collectionView.reloadData()
                    self.view.activityIndicator(isBusy: false)
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
