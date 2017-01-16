//
//  Flickr.swift
//  VirtualTourist
//
//  Created by Badri Narayanan Ravichandran Sathya on 1/4/17.
//  Copyright © 2017 Badri Narayanan Ravichandran Sathya. All rights reserved.
//

import Foundation

import Alamofire
import AlamofireImage
import MapKit
import SwiftyJSON

class  Flickr {
    static var page: Int = 0;
    
    func getPhotos(coordinate: CLLocationCoordinate2D, completionHandler: @escaping (_ flickrSearchResults: FlickrSearchResults?, _ status: String) -> ()) {
        Alamofire.request(getUrl(coordinate: coordinate).absoluteString).responseJSON { (response) in
            var flickrSearchResults: FlickrSearchResults;
            switch response.result {
            case .success(let data):
                let json = JSON(data)
                let flickrPhotos = self.getPhotosFromJson(json: json)
                flickrSearchResults = FlickrSearchResults(photos: flickrPhotos)
                completionHandler(flickrSearchResults, "Success")
            case .failure(let error):
                print("Request Failed with error: \(error)")
                completionHandler(nil, "Failure")
            }
        }
    }
    
    func getUrl(coordinate: CLLocationCoordinate2D) -> URL {
        let constants = FlickrRequestValues()
        var urlComponents = URLComponents()
        urlComponents.scheme = constants.PROTOCOL
        urlComponents.host = constants.API_PATH
        urlComponents.path = constants.PATH
        let methodQueryItem = URLQueryItem(name: "method", value: constants.METHOD)
        let apiKeyQueryItem = URLQueryItem(name: "api_key", value: constants.API_KEY)
        let radiusQueryItem = URLQueryItem(name: "radius", value: "\(constants.RADIUS)")
        let radiusUnitQueryItem = URLQueryItem(name: "radius_unit", value: constants.RADIUS_UNIT)
        let contentTypeQueryItem = URLQueryItem(name: "content_type", value: "\(constants.CONTENT_TYPE)")
        let latitudeQueryItem = URLQueryItem(name: "lat", value: "\(coordinate.latitude)")
        let longitudeQueryItem = URLQueryItem(name: "lon", value: "\(coordinate.longitude)")
        let formatQueryItem = URLQueryItem(name: "format", value: constants.FORMAT)
        let noJsonCallBackQueryItem = URLQueryItem(name: "nojsoncallback", value: "\(constants.NO_JSON_CALL_BACK)")
        let pageQueryItem = URLQueryItem(name: "page", value: "\(Flickr.page+1)")
        let perPageQueryItem = URLQueryItem(name: "per_page", value: "\(constants.PER_PAGE)")
        
        let queryItems = [apiKeyQueryItem, radiusQueryItem, radiusUnitQueryItem, contentTypeQueryItem, methodQueryItem,
                          latitudeQueryItem, longitudeQueryItem, formatQueryItem, noJsonCallBackQueryItem,
                          pageQueryItem, perPageQueryItem]
        urlComponents.queryItems = queryItems
        return urlComponents.url!
    }
    
    func getPhotosFromJson(json: JSON) -> [FlickrPhoto] {
        var flickrPhotos = [FlickrPhoto]()
        let responseConstants = FlickrResponseKeys()
        Flickr.page = json[responseConstants.PHOTOS_KEY][responseConstants.PAGE_KEY].intValue
        let pages = json[responseConstants.PHOTOS_KEY][responseConstants.PAGES_KEY].intValue
        if(Flickr.page>=4000 || Flickr.page>=pages) {
            Flickr.page = 0;
        }
        for photo in json[responseConstants.PHOTOS_KEY][responseConstants.PHOTO_KEY].arrayValue {
            let farm = photo[responseConstants.FARM_KEY].intValue
            let id = photo[responseConstants.ID_KEY].stringValue
            let secret = photo[responseConstants.SECRET_KEY].stringValue
            let server = photo[responseConstants.SERVER_KEY].stringValue
            let title = photo[responseConstants.TITLE_KEY].stringValue
            flickrPhotos.append(FlickrPhoto(photoId: id, farm: farm, server: server, secret: secret, title: title))
        }
        return flickrPhotos
    }
    
    func getPhotosFromUrl(flickrPhoto: FlickrPhoto, completionHandler: @escaping(_ data: [String: AnyObject]?, _ status: String) -> ()) {
        let thumbnailUrl = flickrPhoto.flickrImageURL()
        let largePhotoUrl = flickrPhoto.flickrImageURL()
        
        self.getPhoto(url: thumbnailUrl!, flickrPhoto: flickrPhoto) { (dictionary, status) in
            if(status == "Success") {
                self.getPhoto(url: largePhotoUrl!, flickrPhoto: flickrPhoto, completionHandler: { (dictionaryLarge, status) in
                    completionHandler(dictionaryLarge, status)
                })
            }
            else {
                completionHandler(nil, status)
            }
        }
    }
    
    func getPhoto(url: URL, flickrPhoto: FlickrPhoto, completionHandler: @escaping(_ data: [String: AnyObject], _ status: String) -> ()) {
        var dictionary = [String: AnyObject]()
        Alamofire.request(url.absoluteString).responseImage { (response) in
            switch response.result {
            case .success(let data):
                flickrPhoto.image = data
                dictionary = ["flickrPhoto": flickrPhoto]
                completionHandler(dictionary, "Success")
            case .failure(let error):
                print("Image download failure: \(error.localizedDescription), Url: \(url)")
                completionHandler(dictionary, "Failure")
            }
        }
    }
    
    func getAddressFromLatLng(latitude: Double, longitude: Double , completionHandler: @escaping(_ data: String) -> ()) {
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)) { (placemarks, error) in
            if (error != nil) {
                print("reverse geodcode fail: \(error?.localizedDescription)")
                completionHandler("No Address Found")
            }
            var placemark: CLPlacemark
            
            if((placemarks?.count)!>0) {
                placemark = (placemarks?[0])!
                if placemark.locality != nil {
                    completionHandler(placemark.locality!)
                } else {
                    completionHandler("No Address found")
                }
            } else {
                completionHandler("No Address Found")
            }
        }
    }
    
}
