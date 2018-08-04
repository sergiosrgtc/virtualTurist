//
//  FlickrApi.swift
//  virtualTourist
//
//  Created by Sergio Costa on 30/07/18.
//  Copyright © 2018 Sergio Costa. All rights reserved.
//

import Foundation

class FlickrApi: NSObject {
    
    static let SharedInstance = FlickrApi()
    
    private func searchParameters(lat: String, lon: String, page: Int) -> [String: AnyObject]{
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(lat: lat, lon: lon),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.Page: page

            ] as [String : AnyObject]
        return methodParameters
    }
    
    private func bboxString(lat: String, lon: String) -> String {
        // ensure bbox is bounded by minimum and maximums
        if let latitude = Double(lat), let longitude = Double(lon) {
            let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
            let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
            let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
            let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        } else {
            return "0,0,0,0"
        }
    }
    
    // MARK:- Flickr API
   
    func searchPicturesBy(lat: String, lon: String, withPageNumber: Int = 1, completionHandler: @escaping (_ flickerPics: FlickerPic) -> Void) {
        let methodParameters = searchParameters(lat: lat, lon: lon, page: withPageNumber)
        // add the page to the method's parameters
        var methodParametersWithPageNumber = methodParameters
        
        // create session and request
        let session = URLSession.shared
        print(flickrURLFromParameters(methodParameters))
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(_ error: String) {
                print(error)
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            if let flickerPics = try? JSONDecoder().decode(FlickerPic.self, from: data){
                completionHandler(flickerPics)
            }
        }
        
        // start the task!
        task.resume()
    }
    
    func searchRandomPicturesBy(lat: String, lon: String, completionHandler: @escaping (_ flickerPics: FlickerPic) -> Void) {
        let methodParameters = searchParameters(lat: lat, lon: lon, page: 1)
        // add the page to the method's parameters
        var methodParametersWithPageNumber = methodParameters
        
        // create session and request
        let session = URLSession.shared
        print(flickrURLFromParameters(methodParameters))
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(_ error: String) {
                print(error)
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            if let flickerPics = try? JSONDecoder().decode(FlickerPic.self, from: data){
                // pick a random page!
                if let totalPages = flickerPics.photoAlbum?.pages{
                    let pageLimit = min(totalPages, 40)
                    let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                    FlickrApi.SharedInstance.searchPicturesBy(lat: lat, lon: lon, withPageNumber: randomPage) { (flickrPics) in
                        completionHandler(flickerPics)
                    }
                }
            }
        }
        
        // start the task!
        task.resume()
    }
    
    // MARK: Helper for Creating a URL from Parameters
    
    private func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
}
