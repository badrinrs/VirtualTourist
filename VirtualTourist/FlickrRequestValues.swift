//
//  Flickr.swift
//  VirtualTourist
//
//  Created by Badri Narayanan Ravichandran Sathya on 1/4/17.
//  Copyright © 2017 Badri Narayanan Ravichandran Sathya. All rights reserved.
//

import Foundation

struct FlickrRequestValues {
    let API_KEY = "4a0eced7ec9e6da268e343fc7e3ab371"
    let API_PATH = "api.flickr.com"
    let SAFE_SEARCH = 1
    let CONTENT_TYPE = 7
    let RADIUS = 20
    let RADIUS_UNIT = "mi"
    let PROTOCOL = "https"
    let METHOD = "flickr.photos.search"
    let PATH = "/services/rest"
    let FORMAT = "json"
    let PER_PAGE = 20
    let NO_JSON_CALL_BACK = 1
}

