//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Badri Narayanan Ravichandran Sathya on 1/3/17.
//  Copyright © 2017 Badri Narayanan Ravichandran Sathya. All rights reserved.
//

import Foundation
import UIKit
extension UIViewController {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
