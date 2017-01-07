//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Badri Narayanan Ravichandran Sathya on 1/7/17.
//  Copyright © 2017 Badri Narayanan Ravichandran Sathya. All rights reserved.
//

import Foundation
import CoreData
import UIKit


public class Photo: NSManagedObject {
    convenience init(photo: FlickrPhoto, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            let data = UIImagePNGRepresentation(photo.image!) as NSData?
            self.photo = data
            self.title = photo.title
            self.url = photo.flickrImageURL()?.absoluteString
            self.addedAt = Date() as NSDate?
        } else {
            fatalError("Unable to find Entity name \"Photo\"!")
        }
    }

}
