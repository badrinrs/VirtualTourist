//
//  Pin+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Badri Narayanan Ravichandran Sathya on 1/7/17.
//  Copyright © 2017 Badri Narayanan Ravichandran Sathya. All rights reserved.
//

import Foundation
import CoreData


public class Pin: NSManagedObject {
    convenience init(annotation: PinAnnotation, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: ent, insertInto: context)
            self.latitude = annotation.coordinate.latitude
            self.longitude = annotation.coordinate.longitude
            self.title = annotation.title
            self.addedAt = Date() as NSDate?
            self.modifiedAt = Date() as NSDate?
        } else {
            fatalError("Unable to find Entity name \"Pin\"!")
        }
        
    }
    
    func setNewLocation(annotation: PinAnnotation, context: NSManagedObjectContext) {
        self.latitude = annotation.coordinate.latitude
        self.longitude = annotation.coordinate.longitude
        self.title = annotation.title
        self.modifiedAt = Date() as NSDate?
    }

}
