//
//  ViewController+ShowAlert.swift
//  OntheMap
//
//  Created by Sergio Costa on 02/07/18.
//  Copyright © 2018 Sergio Costa. All rights reserved.
//

import UIKit

extension UIViewController{
    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}
