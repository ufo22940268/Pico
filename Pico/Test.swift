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
    
//    func run() {
//        let upImage = CIImage(image: UIImage(named: "outputUIImage_11")!)!
//        let downImage = CIImage(image: UIImage(named: "IMG_3315")!)!
//
//
////        let outputImage = upImage.applyingFilter("CISubtractBlendMode", parameters: ["inputBackgroundImage": downImage])
////        let outputImage = upImage.applyingFilter("CILineOverlay")
////        let outputImage = upImage.applyingFilter("CILineOverlay").applyingFilter("CIColorInvert").applyingFilter("CIDifferenceBlendMode", parameters: ["inputBackgroundImage": downImage.applyingFilter("CILineOverlay").applyingFilter("CIColorInvert")])
//
//        let outputImage = upImage.applyingFilter("CIRowAverage", parameters: ["inputExtent": CIVector(cgRect: upImage.extent)])
//        let outputUIImage = outputImage.convertToUIImage()
//        print("finish")
//    }
//
    func run() {
        let upImage = UIImage(named: "IMG_3314")!.cgImage!
        let downImage = UIImage(named: "IMG_3315")!.cgImage!

        let request = VNTranslationalImageRegistrationRequest(targetedCGImage: downImage, completionHandler: { (req, error) in
            // ty should be the gap from top to middle of up image
            // ty should be negative
//            print("result count: \(req.results?.count)")
            print("test alignment", (req.results!.first as! VNImageTranslationAlignmentObservation).alignmentTransform)
//            print(req.results!.first!)
//            print((req.results!.first! as! VNImageHomographicAlignmentObservation).warpTransform)
        })

        try! VNImageRequestHandler(cgImage: upImage, options: [:]).perform([request])
    }
}
