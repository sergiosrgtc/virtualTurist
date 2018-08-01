//
//  GCDBlackBox.swift
//  virtualTourist
//
//  Created by Sergio Costa on 30/07/18.
//  Copyright © 2018 Sergio Costa. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
