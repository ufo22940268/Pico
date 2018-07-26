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

class OverlapDetector {
    
    var upImage: UIImage!
    var downImage: UIImage!
    var upRGB: RGBAImage!
    var downRGB: RGBAImage!
    
    let invalidPercentThreshold = Float(0.05)

    init(upImage: UIImage, downImage: UIImage) {
        
        self.upImage = upImage
        self.downImage = downImage
        self.upRGB = RGBAImage(image: upImage)!
        self.downRGB = RGBAImage(image: downImage)!
    }
    
    enum Position: String {
        case top = "top"
        case bottom = "bottom"
    }
    
    func getOverlapFromTopOfDownImage() -> Int {
        var untilLine = 0
        for y in 0..<upRGB.height {
            var invalidDot = 0
            for x in 0..<upRGB.width {
                if upRGB.pixel(x: x, y) != downRGB.pixel(x: x, y) {
                    invalidDot = invalidDot + 1
                }
            }
            
            let invalidPercent: Float = Float(invalidDot)/Float(upRGB.width)
            if invalidPercent > invalidPercentThreshold {
                untilLine = y
                break
            }
        }
        return untilLine
    }
    
    func getOverlapFromBottomOfUpImage() -> Int {
        var overlapHeight = 0
        for y in (0..<upRGB.height).reversed() {
            var invalidDot = 0
            for x in 0..<upRGB.width {
                if upRGB.pixel(x: x, y) != downRGB.pixel(x: x, y) {
                    invalidDot = invalidDot + 1
                }
            }
            
            let invalidPercent: Float = Float(invalidDot)/Float(upRGB.width)
            if invalidPercent > invalidPercentThreshold {
                overlapHeight = upRGB.height - y
                break
            }
        }
        return overlapHeight
    }
    
    func isLineInvalid(image1: RGBAImage, image1Y: Int, image2: RGBAImage, image2Y: Int) -> Bool {
        var invalidDot = 0
        for x in 0..<image1.width {
            if image1.pixel(x: x, image1Y) != image2.pixel(x: x, image2Y) {
                invalidDot = invalidDot + 1
            }
        }
        
        let invalidPercent: Float = Float(invalidDot)/Float(upRGB.width)
        return invalidPercent > invalidPercentThreshold
    }
    
    func setupRectRequest(request: VNDetectRectanglesRequest) {
        request.maximumObservations = 8 // Vision currently supports up to 16.
        request.minimumConfidence = 0.4 // Be confident.
        request.minimumAspectRatio = 0.01 // height / width
    }
    
    func getRectangleMayOverlap(completeHandler: @escaping (CGRect, CGRect) -> Void) {
        let group = DispatchGroup()
        var upRect: VNRectangleObservation!
        
        //Handle up image
        group.enter()
        let upRectReqeust = VNDetectRectanglesRequest(completionHandler: {(request, error) in
            if let results = request.results, !results.isEmpty {
                let rectResults = results as! [VNRectangleObservation]
                let bottomLeftRect = rectResults.min(by: { (lhs, rhs) -> Bool in
                    return lhs.bottomLeft.y < rhs.bottomLeft.y
                })
                upRect = bottomLeftRect
            }
            group.leave()
        })
        setupRectRequest(request: upRectReqeust)
        try! VNImageRequestHandler(cgImage: upImage.cgImage!, options: [:]).perform([upRectReqeust])

        //Handle down image
        var downRect: VNRectangleObservation!
        group.enter()
        let downRectReqeust = VNDetectRectanglesRequest(completionHandler: {(request, error) in
            if let results = request.results, !results.isEmpty {
                let rectResults = results as! [VNRectangleObservation]
                let bottomLeftRect = rectResults.max(by: { (lhs, rhs) -> Bool in
                    return lhs.bottomLeft.y < rhs.bottomLeft.y
                })
                downRect = bottomLeftRect
            }
            group.leave()
        })
        setupRectRequest(request: downRectReqeust)
        try! VNImageRequestHandler(cgImage: downImage.cgImage!, options: [:]).perform([downRectReqeust])

        group.notify(queue: .global()) {
            completeHandler(upRect.toRect(size: self.upImage.size), downRect.toRect(size: self.upImage.size))
        }
    }

    func getMiddleIntersection(completeHandler: @escaping (CGFloat, CGFloat) -> Void) {
        let handleRectangle = {(upRect: CGRect, downRect: CGRect) in
            print(upRect, downRect)
            
            var upRectInCGImage = upRect
            upRectInCGImage.origin.y = self.upImage.size.height - upRectInCGImage.maxY
            var downRectInCGImage = downRect
            downRectInCGImage.origin.y = self.upImage.size.height - downRectInCGImage.maxY + 20
            let upRectImage = self.upImage.cgImage!.cropping(to: upRectInCGImage)
            let downRectImage = self.downImage.cgImage!.cropping(to: downRectInCGImage)
            let request = VNTranslationalImageRegistrationRequest(targetedCGImage: downRectImage!, options: [:], completionHandler: {(request, error) in
                let imageOverlap = abs((request.results?.first as? VNImageTranslationAlignmentObservation)?.alignmentTransform.ty ?? 0)
                let upOverlap = self.upImage.size.height - (upRectInCGImage.minY + imageOverlap)
                print("upOverlap", upOverlap)
                
                let downOverlap = downRectInCGImage.minY
                print("downOverlap", downOverlap)
                
                completeHandler(upOverlap, downOverlap)
            })
            
            try! VNImageRequestHandler(cgImage: upRectImage!, options: [:]).perform([request])
        }
        getRectangleMayOverlap(completeHandler: handleRectangle)
    }
    
    func detect(completeHandler: @escaping (CGFloat, CGFloat) -> Void) {
        if upImage.size != downImage.size {
            return completeHandler(0, 0)
        }
        
//        let bottomOverlapForUpImage = getOverlapFromBottomOfUpImage()
//        let topOverlapForDownImage = getOverlapFromTopOfDownImage()
        
        getMiddleIntersection(completeHandler: completeHandler)
    }
}
