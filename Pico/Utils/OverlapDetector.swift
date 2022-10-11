 //
//  OverlapDetector.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/10.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import Vision

struct RectangleResult {
    var bundle: (VNRectangleObservation, VNRectangleObservation)?
    var strictBundle: (VNRectangleObservation, VNRectangleObservation)?
    var largestRect: CGRect?
    var topRect: CGRect?
    var bottomRect: CGRect?
    
    static func empty() -> RectangleResult {
        return self.init(bundle: nil, strictBundle: nil, largestRect: nil, topRect: nil, bottomRect: nil)
    }
}

class OverlapDetector {
    
    var upImage: UIImage!
    var downImage: UIImage!
    var frameResult: FrameDetectResult!
    
    init(upImage: UIImage, downImage: UIImage, frameResult: FrameDetectResult = FrameDetectResult.zero()) {
        self.upImage = upImage
        self.downImage = downImage
        self.frameResult = frameResult
    }
    
    func translation(regionHeight originHeight: CGFloat, fromMiddle:Bool = true,  complete: @escaping (CGFloat?, CGFloat?, CGFloat?) -> Void) {
        var regionHeight = originHeight
        let height = regionHeight*CGFloat(upImage.size.height)
        let leftHeight = CGFloat(upImage.size.height) - CGFloat(height)
        let request = VNTranslationalImageRegistrationRequest(targetedCGImage: downImage.cgImage!, completionHandler: { (req, error) in
            if let first = req.results?.first, let obs = first as? VNImageTranslationAlignmentObservation {
                print(regionHeight, obs.alignmentTransform)
                if obs.alignmentTransform.ty < 0 && obs.alignmentTransform.tx == 0 {
                    let upShift = leftHeight
                    let downShift = CGFloat(self.upImage.size.height) - (abs(obs.alignmentTransform.ty) + leftHeight)
                    print(regionHeight, obs.alignmentTransform, upShift, downShift)
                    complete(upShift, downShift, abs(obs.alignmentTransform.ty))
                } else {
                    complete(nil, nil, nil)
                }
            }
        })
        
        if fromMiddle {
            request.regionOfInterest = CGRect(x: 0, y: 0.5 - regionHeight/2, width:1, height:regionHeight)
        } else {
            request.regionOfInterest = CGRect(x: 0, y: 1 - regionHeight, width:1, height:regionHeight)
        }

        try! VNImageRequestHandler(cgImage: upImage.cgImage!, options: [:]).perform([request])
    }
    
    func detect(completeHandler: @escaping (CGFloat, CGFloat) -> Void) {
        let heights = stride(from: 1, through: 9, by: 1).map { (index) -> [CGFloat] in
            let f = CGFloat(index)/10
//            return stride(from: 1, to: 9, by: 2).map {f + CGFloat($0)/1000}
            return [f]
        }.joined()
        
        let group = DispatchGroup()
        var upOverlap:CGFloat? = nil
        var downOverlap:CGFloat? = nil
        var tyOverlap:CGFloat? = nil
        
//        for regionHeight in heights {
//            group.enter()
//            count = count + 1
//            translation(regionHeight: regionHeight, fromMiddle: true) { (up, down, ty) in
//                if let down = down {
//                    if downOverlap == nil || up! + down < upOverlap! + downOverlap! {
//                        upOverlap = up
//                        downOverlap = down
//                        tyOverlap = ty
////                        print("down: \(down)")
//                    }
//                }
//                group.leave()
//            }
//        }
        
        for regionHeight in heights {
            group.enter()
            translation(regionHeight: regionHeight, fromMiddle: false) { (up, down, ty) in
                if let down = down {
                    if downOverlap == nil || up! + down < upOverlap! + downOverlap! {
                        upOverlap = up
                        downOverlap = down
                        tyOverlap = ty
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            print("complete: \(upOverlap) \(downOverlap)")
            completeHandler(upOverlap ?? 0, downOverlap ?? 0)
        }
    }
}
