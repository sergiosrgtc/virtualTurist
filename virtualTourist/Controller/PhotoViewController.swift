//
//  PhotoViewController.swift
//  virtualTourist
//
//  Created by Sergio Costa on 31/07/18.
//  Copyright © 2018 Sergio Costa. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController {
    @IBOutlet weak var imagem: UIImageView!
    
    var dataController = DataController.sharedInstance
    var photo : Photo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = photo?.name!
        if let pic = photo?.image{
            imagem.image = UIImage.init(data: pic)
        }
    }
    
    @IBAction func deletePhoto(_ sender: Any) {
        dataController.viewContext.delete(photo!)
        try? dataController.viewContext.save()
        self.navigationController?.popViewController(animated: true)
    }
}
