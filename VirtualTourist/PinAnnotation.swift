//
//  PinAnnotation.swift
//  VirtualTourist
//
//  Created by Badri Narayanan Ravichandran Sathya on 1/4/17.
//  Copyright © 2017 Badri Narayanan Ravichandran Sathya. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class PinAnnotation: NSObject, MKAnnotation {
    var title: String?
    var coordinate: CLLocationCoordinate2D
    var subtitle: String?
    
    init(title: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.coordinate = coordinate
        self.subtitle = "Coordinate: \(coordinate.latitude.roundTo(places: 2)), \(coordinate.longitude.roundTo(places: 2))"
    }
}
