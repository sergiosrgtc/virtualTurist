//
//  ViewController+ActivityView.swift
//  OntheMap
//
//  Created by Sergio Costa on 07/07/18.
//  Copyright © 2018 Sergio Costa. All rights reserved.
//

import UIKit

extension UIView{
    
    func activityIndicator(isBusy: Bool = true, activityColor: UIColor = UIColor.white, backgroundColor: UIColor =  UIColor.black.withAlphaComponent(0.5)) {
        if isBusy{
            let backgroundView = UIView()
            backgroundView.frame = CGRect.init(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
            backgroundView.backgroundColor = backgroundColor
            backgroundView.tag = 77777
            
            var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
            activityIndicator = UIActivityIndicatorView(frame: CGRect.init(x: 0, y: 0, width: 50, height: 50))
            activityIndicator.center = self.center
            activityIndicator.hidesWhenStopped = true
            activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
            activityIndicator.color = activityColor
            activityIndicator.startAnimating()
            self.isUserInteractionEnabled = false
            
            backgroundView.addSubview(activityIndicator)
            
            self.addSubview(backgroundView)
        }else{
            if let background = viewWithTag(77777){
                background.removeFromSuperview()
            }
            self.isUserInteractionEnabled = true
        }
    }
}
