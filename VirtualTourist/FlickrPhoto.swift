//
//  FlickrPhoto.swift
//  VirtualTourist
//
//  Created by Badri Narayanan Ravichandran Sathya on 1/4/17.
//  Copyright © 2017 Badri Narayanan Ravichandran Sathya. All rights reserved.
//

import Foundation
import UIKit

class FlickrPhoto {
    var image: UIImage?
    var photoId: String
    var farm: Int
    var server: String
    var secret: String
    var title: String
    
    init(photoId: String, farm: Int, server: String, secret: String, title: String) {
        self.photoId = photoId
        self.farm = farm
        self.server = server
        self.secret = secret
        self.title = title
    }
    
    func flickrImageURL() -> URL? {
        if let url =  URL(string: "https://farm\(farm).staticflickr.com/\(server)/\(photoId)_\(secret).jpg") {
            return url
        }
        return nil
    }
    
    init(title: String, image: UIImage) {
        self.title = title
        self.image = image
        self.photoId = ""
        self.farm = 0
        self.secret = ""
        self.server = ""
    }
    
    
}
