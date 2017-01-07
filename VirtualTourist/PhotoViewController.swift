//
//  PhotoViewController.swift
//  VirtualTourist
//
//  Created by Badri Narayanan Ravichandran Sathya on 1/4/17.
//  Copyright © 2017 Badri Narayanan Ravichandran Sathya. All rights reserved.
//

import Foundation
import UIKit

class PhotoViewController: UIViewController {
    
    @IBOutlet weak var collectionImage: UIImageView!
    @IBOutlet weak var imageTitle: UILabel!
    var flickrPhoto: FlickrPhoto!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionImage.image = flickrPhoto.image
        imageTitle.text = flickrPhoto.title
    }

}
