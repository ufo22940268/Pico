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
    
    let tolerateDiffSize = CGFloat(0.01)

    init(upImage: UIImage, downImage: UIImage) {
        
        self.upImage = upImage
        self.downImage = downImage
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
        request.minimumConfidence = 0.2
        // Be confident.
        request.minimumAspectRatio = 0.1 // height / width
        request.maximumAspectRatio = 1.0
        request.minimumSize = 0.05
    }
    
    func getRectangleMayOverlap(completeHandler: @escaping (CGRect, CGRect) -> Void) {
        let group = DispatchGroup()
        
        var upRectObs = [VNRectangleObservation]()
        var downRectObs = [VNRectangleObservation]()

        //Handle up image
        group.enter()
        let upRectReqeust = VNDetectRectanglesRequest(completionHandler: {(request, error) in
            if let results = request.results, !results.isEmpty {
                upRectObs = results as! [VNRectangleObservation]
                
            }
            group.leave()
        })
        setupRectRequest(request: upRectReqeust)
        try! VNImageRequestHandler(cgImage: upImage.cgImage!, options: [:]).perform([upRectReqeust])

        //Handle down image
        group.enter()
        let downRectReqeust = VNDetectRectanglesRequest(completionHandler: {(request, error) in
            if let results = request.results, !results.isEmpty {
                downRectObs = results as! [VNRectangleObservation]
            }
            group.leave()
        })
        setupRectRequest(request: downRectReqeust)
        try! VNImageRequestHandler(cgImage: downImage.cgImage!, options: [:]).perform([downRectReqeust])

        group.notify(queue: .global()) {
//            print("upObs", upRectObs.map {$0.toRect().size})
//            print("downObs", downRectObs.map {$0.toRect().size})
            if let (upObs, downObs) = self.findMatchingObsBetween(up: upRectObs, down: downRectObs) {
//                print(upObs.toRect(), downObs.toRect())
                completeHandler(upObs.toRect(size: self.upImage.size), downObs.toRect(size: self.downImage.size))
            } else {
                completeHandler(CGRect.zero, CGRect.zero)
            }
        }
    }
    
    func isSizeToleratable(_ size1: CGFloat, _ size2: CGFloat) -> Bool {
        return abs(size1 - size2) < tolerateDiffSize
    }
    
    func findMatchingObsBetween(up: [VNRectangleObservation], down: [VNRectangleObservation]) -> (VNRectangleObservation,VNRectangleObservation)? {
        let sortedUp = up.sorted(by: { (l, r) -> Bool in
            return l.bottomLeft.y < r.bottomLeft.y
        })
        let sortedDown = down.sorted(by: { (l, r) -> Bool in
            return l.bottomLeft.y > r.bottomLeft.y
        })

        for upObs in (sortedUp.filter { $0.bottomLeft.y < 0.5 }) {
            for downObs in (sortedDown.filter {$0.bottomLeft.y > 0.5}) {
                if isSizeToleratable(upObs.toRect().width, downObs.toRect().width) && isSizeToleratable(upObs.toRect().height, downObs.toRect().height) {
                    return (upObs, downObs)
                }
            }
        }

        for upObs in (sortedUp.filter { $0.bottomLeft.y >= 0.5 }) {
            for downObs in (sortedDown.filter {$0.bottomLeft.y <= 0.5}) {
                if isSizeToleratable(upObs.toRect().width, downObs.toRect().width) && isSizeToleratable(upObs.toRect().height, downObs.toRect().height) {
                    return (upObs, downObs)
                }
            }
        }
        return nil
    }

    func getMiddleIntersection(completeHandler: @escaping (CGFloat, CGFloat) -> Void) {
        let handleRectangle = {(upRect: CGRect, downRect: CGRect) in
            guard upRect != CGRect.zero && downRect != CGRect.zero else {
                completeHandler(0, 0)
                return
            }
            
            var upRectInCGImage = upRect
            upRectInCGImage.origin.y = self.upImage.size.height - upRectInCGImage.maxY
            var downRectInCGImage = downRect
            downRectInCGImage.origin.y = self.upImage.size.height - downRectInCGImage.maxY
            let upRectImage = self.upImage.cgImage!.cropping(to: upRectInCGImage)
            let downRectImage = self.downImage.cgImage!.cropping(to: downRectInCGImage)
            let request = VNTranslationalImageRegistrationRequest(targetedCGImage: downRectImage!, options: [:], completionHandler: {(request, error) in
                let imageOverlap = abs((request.results?.first as? VNImageTranslationAlignmentObservation)?.alignmentTransform.ty ?? 0)
                let upOverlap = self.upImage.size.height - (upRectInCGImage.minY + imageOverlap)                
                let downOverlap = downRectInCGImage.minY
                
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
        
        getMiddleIntersection(completeHandler: completeHandler)
    }
}
