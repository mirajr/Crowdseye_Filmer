//
//  utility_functions.swift
//  Project Godseye
//
//  Created by Patrick O'Grady on 10/9/15.
//  Copyright © 2015 A Day at the Beach. All rights reserved.
//

import Foundation

func getDataFromUrl(url:NSURL, completion: ((data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void)) {
    NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
        completion(data: data, response: response, error: error)
        }.resume()
}

func downloadImage(url: NSURL, myImageView: UIImageView){
    print("Started downloading \"\(url.URLByDeletingPathExtension!.lastPathComponent!)\".")
    getDataFromUrl(url) { (data, response, error)  in
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            guard let data = data where error == nil else { return }
            print("Finished downloading \"\(url.URLByDeletingPathExtension!.lastPathComponent!)\".")
            myImageView.image = UIImage(data: data)
        }
    }
}