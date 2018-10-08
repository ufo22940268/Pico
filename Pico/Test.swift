//
//  Test.swift
//  Pico
//
//  Created by Frank Cheng on 2018/8/24.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import Vision

class Test {
    
    func run() {
        let movieScreenshots = ["movie_IMG_3942","movie_IMG_3945","movie_IMG_3947", "movie_IMG_3950", "IMG_3955"].map{UIImage(named: $0)!}
        movieScreenshots.forEach {image in
            Image.detectType(image: image, complete: { (type) in
                print(type)
            })
        }
    }
    
//    func run() {
//        let upImage = UIImage(named: "IMG_3314")!.cgImage!
//        let downImage = UIImage(named: "IMG_3315")!.cgImage!
//
//        let request = VNTranslationalImageRegistrationRequest(targetedCGImage: downImage, completionHandler: { (req, error) in
//            // ty should be the gap from top to middle of up image
//            // ty should be negative
//            print("test alignment", (req.results!.first as! VNImageTranslationAlignmentObservation).alignmentTransform)
//        })
//
//        try! VNImageRequestHandler(cgImage: upImage, options: [:]).perform([request])
//    }
}
