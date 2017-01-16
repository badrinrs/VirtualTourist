//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Badri Narayanan Ravichandran Sathya on 1/3/17.
//  Copyright © 2017 Badri Narayanan Ravichandran Sathya. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {

    @IBOutlet weak var touristMap: MKMapView!
    
    let locationManager = CLLocationManager()
    
    var pins = [Pin]()
    
    var context: NSManagedObjectContext!
    
    fileprivate var pinConsidered: Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        touristMap.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        context = appDelegate.persistentContainer.viewContext
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
        touristMap.isZoomEnabled = true
        touristMap.isScrollEnabled = true
        if let coor = touristMap.userLocation.location?.coordinate{
            touristMap.setCenter(coor, animated: true)
        }
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addPinToMap(gestureRecognizer:)))
        longPressGestureRecognizer.numberOfTouchesRequired = 1
        touristMap.addGestureRecognizer(longPressGestureRecognizer)
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Pin")
        do {
            pins = try context.fetch(fetchRequest) as! [Pin]
            let annotations = createAnnotationsFromPins(pins: pins)
            touristMap.addAnnotations(annotations)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            showAlert(title: "Error", message: "Error Fetching Information. Please Try Again Later!")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        locationManager.stopUpdatingLocation()
    }

    func addPinToMap(gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.began {
            let touchPoint = gestureRecognizer.location(in: touristMap)
            let newCoordinates = touristMap.convert(touchPoint, toCoordinateFrom: touristMap)
            
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude), completionHandler: {(placemarks, error) -> Void in
                if error != nil {
                    print("Reverse geocoder failed with error" + (error?.localizedDescription)!)
                    return
                }
                
                var annotation: PinAnnotation
                if (placemarks?.count)! > 0 {
                    let pm = placemarks?[0]
                    
                    // not all places have thoroughfare & subThoroughfare so validate those values
                    let location = pm?.locality?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    
                    if (location == "" || location == nil) {
                        annotation = PinAnnotation(title: "Unknown Place", coordinate: newCoordinates)
                    } else {
                        annotation = PinAnnotation(title: (pm?.locality)!, coordinate: newCoordinates)
                    }
                    let flickr = Flickr()
                    flickr.getPhotos(coordinate: annotation.coordinate) { (flickrSearchResults, status) in
                        if(status == "Success") {
                            annotation.searches = flickrSearchResults
                        }
                    }
                    self.touristMap.addAnnotation(annotation)
                    let pin = Pin(annotation: annotation, context: self.context)
                    do {
                        try self.context.save()
                    } catch let error as NSError {
                        print("Could not fetch. \(error), \(error.userInfo)")
                    }
                    self.pins.append(pin)
                }
                else {
                    annotation = PinAnnotation(title: "Unknown Place", coordinate: newCoordinates)
                    self.touristMap.addAnnotation(annotation)
                    let pin = Pin(annotation: annotation, context: self.context)
                    do {
                        try self.context.save()
                    } catch let error as NSError {
                        print("Could not fetch. \(error), \(error.userInfo)")
                    }
                    self.pins.append(pin)
                }
            })
        }
    }
}

extension MapViewController: CLLocationManagerDelegate, MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "pin"
        if !(annotation is PinAnnotation) {
            return nil
        }
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
        
        if(pinView == nil) {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
        } else {
            pinView!.annotation = annotation
        }
        
        pinView!.canShowCallout = true
        pinView!.pinTintColor = .purple
        pinView!.isDraggable = true
        pinView!.animatesDrop = true
        
        let detailImage = #imageLiteral(resourceName: "search")
        let detailButton = UIButton(type: .custom)
        detailButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30);
        detailButton.setImage(detailImage, for: .normal)
        pinView!.rightCalloutAccessoryView = detailButton
        
        let deleteImage = #imageLiteral(resourceName: "delete")
        let deleteButton = UIButton(type: .custom)
        deleteButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30);
        deleteButton.setImage(deleteImage, for: .normal)
        pinView!.leftCalloutAccessoryView = deleteButton
        
        return pinView
        
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        var pinConsidered: Pin
        var index: Int
        
        if(control == view.leftCalloutAccessoryView) {
            let latitude = view.annotation?.coordinate.latitude
            let longitude = view.annotation?.coordinate.longitude
            for pin in pins {
                if latitude == pin.latitude && longitude == pin.longitude {
                    pinConsidered = pin
                    index = pins.index(of: pin)!
                    pins.remove(at: index)
                    context.delete(pinConsidered)
                    do {
                        try context.save()
                    } catch let error as NSError {
                        print("Could not fetch. \(error), \(error.userInfo)")
                        showAlert(title: "Error", message: "Error Fetching Information. Please Try Again Later!")
                    }
                    mapView.removeAnnotation(view.annotation!)
                }
            }
        }
            
        else if(control == view.rightCalloutAccessoryView) {
            let latitude = view.annotation?.coordinate.latitude
            let longitude = view.annotation?.coordinate.longitude
            for pin in pins {
                if latitude == pin.latitude && longitude == pin.longitude {
                    pinConsidered = pin
                    index = pins.index(of: pin)!
                    
                    let photoVC = self.storyboard?.instantiateViewController(withIdentifier: "photoMapVC") as! PhotoMapViewController
                    let annotation = view.annotation as! PinAnnotation
                    photoVC.annotation = annotation
                    photoVC.pin = pinConsidered
                    photoVC.searches = annotation.searches
                    self.navigationController?.pushViewController(photoVC, animated: true)
                }
            }
        }
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        switch newState {
        case .starting:
            let annotation = view.annotation
            for pin in pins {
                if(pin.latitude == annotation?.coordinate.latitude && pin.longitude == annotation?.coordinate.longitude) {
                    pinConsidered = pin
                    context.delete(pin)
                    do {
                        try self.context.save()
                    } catch let error as NSError {
                        print("Could not fetch. \(error), \(error.userInfo)")
                    }
                }
            }
        case .ending:
            touristMap.removeAnnotation(view.annotation!)
            let newCoordinates = view.annotation?.coordinate
            view.setDragState(.none, animated: true)
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: (newCoordinates?.latitude)!, longitude: (newCoordinates?.longitude)!), completionHandler: {(placemarks, error) -> Void in
                if error != nil {
                    print("Reverse geocoder failed with error" + (error?.localizedDescription)!)
                    return
                }
                
                var annotation: PinAnnotation
                if (placemarks?.count)! > 0 {
                    let pm = placemarks?[0]
                    
                    // not all places have thoroughfare & subThoroughfare so validate those values
                    let location = pm?.locality?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    
                    if (location == "" || location == nil) {
                        annotation = PinAnnotation(title: "Unknown Place", coordinate: newCoordinates!)
                    } else {
                        annotation = PinAnnotation(title: (pm?.locality)!, coordinate: newCoordinates!)
                    }
                    self.touristMap.addAnnotation(annotation)
                    let pin = Pin(annotation: annotation, context: self.context)
                    do {
                        try self.context.save()
                    } catch let error as NSError {
                        print("Could not fetch. \(error), \(error.userInfo)")
                    }
                    self.pins.append(pin)
                    
                }
                else {
                    annotation = PinAnnotation(title: "Unknown Place", coordinate: newCoordinates!)
                    self.touristMap.addAnnotation(annotation)
                    let pin = Pin(annotation: annotation, context: self.context)
                    do {
                        try self.context.save()
                    } catch let error as NSError {
                        print("Could not fetch. \(error), \(error.userInfo)")
                    }
                    self.pins.append(pin)
                }
            })
            break
        default:
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        
        let location = locations.last! as CLLocation
        
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        self.touristMap.setRegion(region, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        mapView.setRegion(region, animated: true)
    }
    
    func createAnnotationsFromPins(pins: [Pin]) -> [PinAnnotation] {
        var pinAnnotations = [PinAnnotation]()
        
        for pin in pins {
            let pinAnnotation = PinAnnotation(title: pin.title!, coordinate: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude))
            pinAnnotations.append(pinAnnotation)
        }
        return pinAnnotations
    }
}

