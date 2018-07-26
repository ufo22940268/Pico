//
//  MovieDetector.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/13.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import Vision

class MovieDetector {
    
    var movieImage: UIImage
    
    init(uiImage: UIImage?) {
        if let uiImage = uiImage {
            movieImage = uiImage
        } else {
            movieImage = UIImage(named: "images", in: Bundle(path: "movie_screenshot"), compatibleWith: nil)!
        }
    }
    
    
    func subtitleY(callback: @escaping (CGFloat, Error?) -> Void) {
        
        func handleDetectedText(request: VNRequest?, error: Error?) {
//            let box = request?.results?.map {
//                $0 as! VNTextObservation
//                }.first?.characterBoxes?.filter{$0.topLeft.y < 0.5}.first
            
//            let checkboxes = (request?.results?.map {
//                $0 as! VNTextObservation
//                }.map{$0.characterBoxes?.filter{$0.topLeft.y < 0.5}})?.filter({ (vs: [VNRectangleObservation]?) -> Bool in
//                    return (vs?.count ?? 0) > 0
//                })
            
            let checkboxes = (request?.results?.map {
                $0 as! VNTextObservation
                }.map{$0.characterBoxes})

            
            var validRectangle = [VNRectangleObservation]()
            
            if let checkboxes  = checkboxes {
                for checkbox in checkboxes {
                    if let checkbox = checkbox {
                        for rect in checkbox where rect.topLeft.y < 0.5  {
                            validRectangle.append(rect)
                        }
                    }
                }
            }            

            print(validRectangle.first?.topLeft.y)
            if let first = validRectangle.first  {
                return callback(1 - first.topLeft.y, nil)
            }
            
            if let error = error {
                print("vison request error", error)
            }
            callback(0, error)
        }
        
        var textDetectionRequest: VNDetectTextRectanglesRequest = {
            let textDetectRequest = VNDetectTextRectanglesRequest(completionHandler: handleDetectedText)
            // Tell Vision to report bounding box around each character.
            textDetectRequest.reportCharacterBoxes = true
            return textDetectRequest
        }()
        
        let imageRequestHandler = VNImageRequestHandler(cgImage: movieImage.cgImage!, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try! imageRequestHandler.perform([textDetectionRequest])
        }
    }
 
    
}
