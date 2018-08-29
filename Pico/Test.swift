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
        let upImage = UIImage(named: "IMG_3314")!.cgImage!
        let downImage = UIImage(named: "IMG_3315")!.cgImage!

        let request = VNTranslationalImageRegistrationRequest(targetedCGImage: downImage, completionHandler: { (req, error) in
            // ty should be the gap from top to middle of up image
            // ty should be negative
            print("test alignment", (req.results!.first as! VNImageTranslationAlignmentObservation).alignmentTransform)
        })

        try! VNImageRequestHandler(cgImage: upImage, options: [:]).perform([request])
    }
}
