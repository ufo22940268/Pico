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
    
    static func empty() -> RectangleResult {
        return self.init(bundle: nil, strictBundle: nil)
    }
}

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
        request.maximumObservations = 16 // Vision currently supports up to 16.
        request.minimumConfidence = 0.1
        request.minimumAspectRatio = 0.1 // height / width
        request.maximumAspectRatio = 1.0
        request.minimumSize = 0.13
        request.quadratureTolerance = 10
    }
    
    func detectOverlapRectangles(completeHandler: @escaping (RectangleResult) -> Void) {
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
        
        do {
            try VNImageRequestHandler(cgImage: downImage.cgImage!, options: [:]).perform([downRectReqeust])
        } catch {
            print("VNImageRequestHandler error: \(error)")
            return completeHandler(RectangleResult.empty())
        }

        group.notify(queue: .global()) {
            let result = self.findMatchingObsBetween(up: upRectObs, down: downRectObs)
            completeHandler(result)
        }
    }
    
    func isSizeToleratable(_ size1: CGFloat, _ size2: CGFloat) -> Bool {
        return abs(size1 - size2) < tolerateDiffSize
    }
    
    ///
    ///
    /// - Parameters:
    ///   - up: In Left-Bottom-Coordinate.
    ///   - down: In Left-Bottom-Coordinate.
    func findMatchingObsBetween(up: [VNRectangleObservation], down: [VNRectangleObservation]) -> RectangleResult {
        
        let clampYRange = {(obs: VNRectangleObservation) -> Bool in
            return obs.topLeft.y < (1 - 0.1) && obs.bottomLeft.y > 0.1
        }
        
//        debug(image: self.upImage, obsList: up)
        debug(image: self.downImage, obsList: down)

        
        let sortedUp = up.sorted(by: { (l, r) -> Bool in
            return l.bottomLeft.y < r.bottomLeft.y
        }).filter(clampYRange)
        
        let sortedDown = down.sorted(by: { (l, r) -> Bool in
            return l.bottomLeft.y > r.bottomLeft.y
        }).filter(clampYRange)
        
        var obsBundle: (VNRectangleObservation, VNRectangleObservation)?
        var strictObsBundle: (VNRectangleObservation, VNRectangleObservation)?
        
        for upObs in sortedUp {
            for downObs in sortedDown {
                if strictObsBundle == nil && isSizeToleratable(upObs.toRect().width, downObs.toRect().width) && isSizeToleratable(upObs.toRect().height, downObs.toRect().height) {
                    strictObsBundle = (upObs, downObs)
                }
                if obsBundle == nil && isSizeToleratable(upObs.toRect().width, downObs.toRect().width){
                    obsBundle = (upObs, downObs)
                }
            }
        }
        
        return RectangleResult(bundle: obsBundle, strictBundle: strictObsBundle)
    }
    
    
    func debug(image: UIImage, obsList: [VNRectangleObservation]) {
        let map = obsList.map { obs -> (CGRect, CGImage) in
            let rect = VNImageRectForNormalizedRect(obs.toRect(), Int(image.size.width), Int(image.size.height)).convertLTCToLBC(frameHeight: image.size.height)
            return (rect, image.cgImage!.cropping(to: rect)!)
            
        }
        print("ok")
    }
    
    func convertToLTC(rect: CGRect) -> CGRect {
        var newRect = rect
        newRect.origin.y = self.upImage.size.height - newRect.maxY
        return newRect
    }
    
    func extentToTop(rect: CGRect) -> CGRect {
        var newRect = rect
        newRect.origin.y = 0
        newRect.origin.x = 0
        newRect.size.width = upImage.size.width
        newRect.size.height = rect.origin.y + rect.height
        return newRect
    }
    
    func extentToBottom(rect: CGRect) -> CGRect {
        var newRect = rect
        newRect.origin.x = 0
        newRect.size.width = upImage.size.width
        newRect.size.height = upImage.size.height - newRect.origin.y
        return newRect
    }

    func getMiddleIntersection(completeHandler: @escaping (CGFloat, CGFloat) -> Void) {
        let handleRectangle = {(rectangleResult: RectangleResult) in
            guard rectangleResult.bundle != nil else {
                completeHandler(0, 0)
                return
            }
            
            let (upObs, downObs) = rectangleResult.bundle!
            var upRectInLTC = self.convertToLTC(rect: upObs.toRect(size: self.upImage.size))
            var downRectInLTC = self.convertToLTC(rect: downObs.toRect(size: self.upImage.size))
            
            if upRectInLTC.height > downRectInLTC.height {
                downRectInLTC.size.height = upRectInLTC.height
            } else if upRectInLTC.height < downRectInLTC.height {
                upRectInLTC.origin.y = upRectInLTC.origin.y - (downRectInLTC.height - upRectInLTC.height)
                upRectInLTC.size.height = downRectInLTC.height
            }
            
            let upRectImage = self.upImage.cgImage!.cropping(to: upRectInLTC)
            let downRectImage = self.downImage.cgImage!.cropping(to: downRectInLTC)
            
            let request = VNTranslationalImageRegistrationRequest(targetedCGImage: downRectImage!, options: [:], completionHandler: {(request, error) in
                let imageOverlap = (request.results?.first as? VNImageTranslationAlignmentObservation)?.alignmentTransform.ty ?? 0
                
                print("compose alignment", (request.results!.first as! VNImageTranslationAlignmentObservation).alignmentTransform)
                
                if imageOverlap > 0 {
                    //imageOverlap being positive means translation detection failed.
                    if rectangleResult.strictBundle == nil {
                        return completeHandler(0, 0)
                    } else {
                        let (strictUpObs, strictDownObs) = rectangleResult.strictBundle!
                        let strictUpRectInLTC = self.convertToLTC(rect: strictUpObs.toRect(size: self.upImage.size))
                        let strictDownRectInLTC = self.convertToLTC(rect: strictDownObs.toRect(size: self.downImage.size))
                        return completeHandler(strictDownRectInLTC.minY, self.upImage.size.height - strictUpRectInLTC.minY)
                    }
                }
                
                
                // upRectInCGImage coordinate is LTC
                let upOverlap = self.upImage.size.height - (upRectInLTC.origin.y + abs(imageOverlap))
                
                let downOverlap = downRectInLTC.minY
                
                completeHandler(upOverlap, downOverlap)
            })
            
            try! VNImageRequestHandler(cgImage: upRectImage!, options: [:]).perform([request])
        }
        detectOverlapRectangles(completeHandler: handleRectangle)
    }
    
    func detect(completeHandler: @escaping (CGFloat, CGFloat) -> Void) {
        if upImage.size != downImage.size {
            return completeHandler(0, 0)
        }
        
        getMiddleIntersection(completeHandler: completeHandler)
    }
}
