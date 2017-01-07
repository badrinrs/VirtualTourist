//
//  PhotoMapViewController.swift
//  VirtualTourist
//
//  Created by Badri Narayanan Ravichandran Sathya on 1/4/17.
//  Copyright © 2017 Badri Narayanan Ravichandran Sathya. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData
import SwiftSpinner

class PhotoMapViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    var annotation: PinAnnotation!
    var pin: Pin!
    
    @IBOutlet weak var actionBarButton: UIBarButtonItem!
    @IBOutlet weak var trashBarButton: UIBarButtonItem!
    @IBOutlet weak var travelMap: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    @IBOutlet weak var noCollectionsLabel: UILabel!
    fileprivate let itemsPerRow: CGFloat = 3
    fileprivate let reuseIdentifier = "collectionViewCell"
    fileprivate let flickr = Flickr()
    fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    fileprivate var searches = FlickrSearchResults()
    
    fileprivate var isCollectionButtonTapped  = false;
    fileprivate var selectedCells = [UICollectionViewCell]()
    fileprivate var selectedCellIndexes = [IndexPath]()
    
    fileprivate var longPressGesture: UILongPressGestureRecognizer!
    
    fileprivate var singleTapGesture: UITapGestureRecognizer!
    
    fileprivate var isCancelButtonAvailable: Bool = false
    
    fileprivate var photos = [Photo]()
    
    fileprivate var context: NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem?.title = "OK"
        self.navigationController?.title = annotation.title
        trashBarButton.isEnabled = false
        actionBarButton.isEnabled = false
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        context = appDelegate.persistentContainer.viewContext
        
        travelMap.addAnnotation(annotation)
        travelMap.showAnnotations(travelMap.annotations, animated: true)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = true
        collectionView.allowsSelection = true
        
        
        
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(PhotoMapViewController.handleLongPress(gestureRecognizer:)))
        longPressGesture.minimumPressDuration = 0.5
        longPressGesture.delegate = self
        longPressGesture.delaysTouchesBegan = true
        collectionView.addGestureRecognizer(longPressGesture)
        
        singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(PhotoMapViewController.handleTap(gestureRecognizer:)))
        singleTapGesture.delegate = self
        singleTapGesture.delaysTouchesBegan = true
        collectionView.addGestureRecognizer(singleTapGesture)
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", pin)
        guard let photoList = try? context.fetch(fetchRequest) as! [Photo] else {
            noCollectionsLabel.text = "No Photos Found! Please tap on New Collection Button below."
            return
        }
        photos = photoList
        let flickrPhotos = createFlickrPhotos(photos: photos)
        searches = FlickrSearchResults(photos: flickrPhotos)
        collectionView.reloadData()

        
    }
    
    @IBAction func getNewCollection(_ sender: Any) {
        photos = [Photo]()
        newCollectionButton.isEnabled = false
        isCollectionButtonTapped = true
        
        var searches = FlickrSearchResults()
        SwiftSpinner.show("Loading...", animated: true)
        self.collectionView.reloadData()
        for photo in self.photos {
            context.delete(photo)
            do {
                try context.save()
            } catch let error as NSError {
                print("Could not delete. \(error), \(error.userInfo)")
            }
        }
        flickr.getPhotos(coordinate: annotation.coordinate) { (flickrSearchResults, status) in
            if(status=="Success") {
                searches = flickrSearchResults!
                guard let photos = searches.photos else {
                    self.showAlert(title: "Error", message: "Error Getting Photos. Please try again later.")
                    self.noCollectionsLabel.text = "No Photos Found! Please tap on New Collection Button below."
                    return
                }
                if((photos.count) > 0) {
                    DispatchQueue.main.async {
                        self.noCollectionsLabel.text = ""
                        self.noCollectionsLabel.isHidden = true
                    }
                }
                var flickrPhotos = [FlickrPhoto]()
                let photosCount = searches.photos?.count
                var count = 0
                for flickrPhoto in photos {
                    self.flickr.getPhotosFromUrl(flickrPhoto: flickrPhoto, completionHandler: { (dictionary, status) in
                        count += 1;
                        if(status=="Success") {
                            let photo = dictionary?["flickrPhoto"] as! FlickrPhoto
                            
                            DispatchQueue.main.async {
                                flickrPhotos.append(photo)
                                self.searches = FlickrSearchResults(photos: flickrPhotos)
                                self.collectionView.reloadData()
                            }
                        }
                        if(count == photosCount) {
                            for photo in photos {
                                let corePhoto = Photo(photo: photo, context: self.context)
                                self.pin.addToPhoto(corePhoto)
                                self.photos.append(corePhoto)
                                do {
                                    try self.context.save()
                                } catch let error as NSError {
                                    print("Could not insert. \(error), \(error.userInfo)")
                                }
                            }
                            SwiftSpinner.hide()
                        }
                    })
                }
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.newCollectionButton.isEnabled = true
                }
            } else {
                print(status)
                self.showAlert(title: "Error", message: "Error Getting Photos. Please try again later.")
                self.noCollectionsLabel.text = "No Photos Found! Please tap on New Collection Button below."
            }
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let count = searches.photos?.count else {
            noCollectionsLabel.text = "No Photos Found! Please tap on New Collection Button below."
            return 0
        }
        if(count==0) {
            noCollectionsLabel.text = "No Photos Found! Please tap on New Collection Button below."
        }
        return count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                      for: indexPath) as! PhotoCollectionCell
        cell.backgroundColor = .white
        cell.collectionImage.image = photoForIndexPath(indexPath: indexPath).image
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
    @IBAction func trashPhotos(_ sender: Any) {
        for indexPath in selectedCellIndexes {
            searches.photos?.remove(at: indexPath.row)
            context.delete(photos[indexPath.row])
            do {
                try context.save()
            } catch let error as NSError {
                print("Could not delete. \(error), \(error.userInfo)")
                showAlert(title: "Error", message: "Unable to Delete. Please Try Again Later!")
            }
        }
        self.collectionView.deleteItems(at: selectedCellIndexes)
        
        
        for barButtonItem in navigationItem.rightBarButtonItems! {
            if(barButtonItem.title == "Cancel") {
                let index = navigationItem.rightBarButtonItems?.index(of: barButtonItem)
                navigationItem.rightBarButtonItems?.remove(at: index!)
            }
        }
        isCancelButtonAvailable = false
        
    }
    
    @IBAction func sharePhotos(_ sender: Any) {
        
        var images = [UIImage]()
        
        for indexPath in selectedCellIndexes {
            images.append(photoForIndexPath(indexPath: indexPath).image!)
        }
        
        let activityViewController = UIActivityViewController(activityItems: images, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    func handleLongPress(gestureRecognizer: UIGestureRecognizer) {
        if (gestureRecognizer.state != UIGestureRecognizerState.ended){
            return
        }
        let p = gestureRecognizer.location(in: self.collectionView)
        
        if let indexPath: IndexPath = collectionView?.indexPathForItem(at: p){
            trashBarButton.isEnabled = true
            actionBarButton.isEnabled = true
            
            if let cell: UICollectionViewCell = collectionView.cellForItem(at: indexPath) {
                if(cell.isSelected) {
                    cell.isSelected = false
                    let index = selectedCells.index(of: cell)
                    selectedCells.remove(at: index!)
                    selectedCellIndexes.remove(at: index!)
                    cell.backgroundColor = UIColor.clear
                } else {
                    cell.isSelected = true
                    selectedCells.append(cell)
                    selectedCellIndexes.append(indexPath)
                    cell.backgroundColor = UIColor.red
                    if !(isCancelButtonAvailable) {
                        let discardSelectionsButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(PhotoMapViewController.discardSelections))
                        navigationItem.rightBarButtonItems?.append(discardSelectionsButton)
                        isCancelButtonAvailable = true
                    }
                }
            }
        }
    }
    
    func handleTap(gestureRecognizer: UIGestureRecognizer) {
        if(gestureRecognizer.state != .ended) {
            return
        }
        let p = gestureRecognizer.location(in: self.collectionView)
        
        if let indexPath: IndexPath = collectionView.indexPathForItem(at: p) {
            let imageVC = self.storyboard?.instantiateViewController(withIdentifier: "imageVC") as! PhotoViewController
            imageVC.flickrPhoto = photoForIndexPath(indexPath: indexPath)
            self.navigationController?.pushViewController(imageVC, animated: true)
        }
        
    }
    
    func discardSelections() {
        
        
        for cell in selectedCells {
            cell.isSelected = false
            cell.backgroundColor = UIColor.clear
        }
        for barButtonItem in navigationItem.rightBarButtonItems! {
            if(barButtonItem.title == "Cancel") {
                let index = navigationItem.rightBarButtonItems?.index(of: barButtonItem)
                navigationItem.rightBarButtonItems?.remove(at: index!)
            }
        }
        selectedCells.removeAll()
        selectedCellIndexes.removeAll()
        isCancelButtonAvailable = false
        trashBarButton.isEnabled = false
        actionBarButton.isEnabled = false
    }
    
    func createFlickrPhotos(photos: [Photo]) -> [FlickrPhoto] {
        var flickrPhotos = [FlickrPhoto]()
        
        for photo in photos {
            let flickrPhoto = FlickrPhoto(title: photo.title!, image: UIImage(data: photo.photo as! Data, scale: 1.0)!)
            flickrPhotos.append(flickrPhoto)
        }
        
        return flickrPhotos
    }
}

private extension PhotoMapViewController {
    func photoForIndexPath(indexPath: IndexPath) -> FlickrPhoto {
        return searches.photos![(indexPath as NSIndexPath).row]
    }
    
}

