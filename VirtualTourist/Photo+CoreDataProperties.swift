//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Badri Narayanan Ravichandran Sathya on 1/7/17.
//  Copyright © 2017 Badri Narayanan Ravichandran Sathya. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var addedAt: NSDate?
    @NSManaged public var photo: NSData?
    @NSManaged public var title: String?
    @NSManaged public var url: String?
    @NSManaged public var pin: Pin?

}
