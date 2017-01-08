//
//  FlickrSearchResults.swift
//  VirtualTourist
//
//  Created by Badri Narayanan Ravichandran Sathya on 1/4/17.
//  Copyright © 2017 Badri Narayanan Ravichandran Sathya. All rights reserved.
//

import Foundation

struct FlickrSearchResults {
    var photos: [FlickrPhoto]?
    
    init(photos: [FlickrPhoto]) {
        self.photos = photos
    }
    
    init() {
        photos = nil
    }
    
}
