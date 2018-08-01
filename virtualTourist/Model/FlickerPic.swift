//
//  FlickerPic.swift
//  virtualTourist
//
//  Created by Sergio Costa on 31/07/18.
//  Copyright © 2018 Sergio Costa. All rights reserved.
//

//   let flickerPic = try? JSONDecoder().decode(FlickerPic.self, from: jsonData)

import Foundation

struct FlickerPic: Codable {
    let photoAlbum: PhotoAlbum?
    let stat: String?
    
    enum CodingKeys: String, CodingKey {
        case photoAlbum = "photos"
        case stat = "stat"
    }
}

struct PhotoAlbum: Codable {
    let page: Int?
    let pages: Int?
    let perpage: Int?
    let total: String?
    let photo: [FlickPhoto]?
    
    enum CodingKeys: String, CodingKey {
        case page = "page"
        case pages = "pages"
        case perpage = "perpage"
        case total = "total"
        case photo = "photo"
    }
}

struct FlickPhoto: Codable {
    let id: String?
    let owner: String?
    let secret: String?
    let server: String?
    let farm: Int?
    let title: String?
    let ispublic: Int?
    let isfriend: Int?
    let isfamily: Int?
    let urlM: String?
    let heightM: String?
    let widthM: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case owner = "owner"
        case secret = "secret"
        case server = "server"
        case farm = "farm"
        case title = "title"
        case ispublic = "ispublic"
        case isfriend = "isfriend"
        case isfamily = "isfamily"
        case urlM = "url_m"
        case heightM = "height_m"
        case widthM = "width_m"
    }
}
