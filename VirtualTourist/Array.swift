//
//  Array.swift
//  VirtualTourist
//
//  Created by Badri Narayanan Ravichandran Sathya on 1/15/17.
//  Copyright © 2017 Badri Narayanan Ravichandran Sathya. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
    mutating func removeObject(object: Element) {
        if let index = self.index(of: object) {
            remove(at: index)
        }
    }
    
    mutating func removeObjects(objects: [Element]) {
        for object in objects {
            removeObject(object: object)
        }
    }
}
