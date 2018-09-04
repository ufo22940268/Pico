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
    
    let tolerateDiffSize = CGFloat(0.01)

    init(upImage: UIImage, downImage: UIImage, frameResult: FrameDetectResult = FrameDetectResult.zero()) {
        self.upImage = upImage
        self.downImage = downImage
        self.frameResult = frameResult
        
        
        print("gap: \(frameResult.topGap) ----------- \(frameResult.bottomGap)")
    }
    
    enum Position: String {
        case top = "top"
        case bottom = "bottom"
    }
    
    func setupRectRequest(request: VNDetectRectanglesRequest) {
        request.maximumObservations = 16 // Vision currently supports up to 16.
        request.minimumConfidence = 0.1
        request.minimumAspectRatio = 0.1 // height / width
        request.maximumAspectRatio = 1.0
        request.minimumSize = 0.11
        request.quadratureTolerance = 45
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
        return abs(size1 - size2)/min(size1, size2) < 0.1
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
        
        
        
        let sortedUp = up.sorted(by: { (l, r) -> Bool in
            return l.bottomLeft.y < r.bottomLeft.y
        }).filter(clampYRange)
        
        let sortedDown = down.sorted(by: { (l, r) -> Bool in
            return l.bottomLeft.y > r.bottomLeft.y
        }).filter(clampYRange)
        
        var obsBundle: (VNRectangleObservation, VNRectangleObservation)?
        var strictObsBundle: (VNRectangleObservation, VNRectangleObservation)?
        
        debug(image: self.upImage, obsList: sortedUp)
//        debug(image: self.downImage, obsList: sortedDown)

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
        
        let largestRect = [sortedUp.first!.toRect(), sortedDown.first!.toRect()].max { (l, r) -> Bool in
            return l.height < r.height
        }
        
        return RectangleResult(bundle: obsBundle, strictBundle: strictObsBundle, largestRect: largestRect, topRect: sortedDown.first!.toRect(), bottomRect: sortedUp.first!.toRect())
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
            
            let prepares = [self.prepareTranlsate(rectangleResult: rectangleResult, minClip: true), self.prepareTranlsate(rectangleResult: rectangleResult, minClip: false)]
            
            let group = DispatchGroup()
            var imageOverlaps = [TranslationPrepare: CGFloat]()
            for prepare in prepares {
                group.enter()
                let request = VNTranslationalImageRegistrationRequest(targetedCGImage: prepare.downImage, options: [:], completionHandler: {(request, error) in
                    let imageOverlap = (request.results?.first as? VNImageTranslationAlignmentObservation)?.alignmentTransform.ty ?? 0
                    imageOverlaps[prepare] = imageOverlap
                    group.leave()
                })
                try! VNImageRequestHandler(cgImage: prepare.upImage, options: [:]).perform([request])
            }
            
            group.notify(queue: .main, execute: {
                let overlapBundle = imageOverlaps.first(where: { (prepare, overlap) -> Bool in
                    overlap < 0
                })
                
                guard let bundle = overlapBundle else {
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
                
                let prepare = bundle.key
                let imageOverlap = bundle.value

                // upRectInCGImage coordinate is LTC
                let upOverlap = self.upImage.size.height - (prepare.upRect.origin.y + abs(imageOverlap))

                let downOverlap = prepare.downRect.minY

                completeHandler(upOverlap, downOverlap)
            })

        }
        detectOverlapRectangles(completeHandler: handleRectangle)
    }
    
    struct TranslationPrepare:Hashable {
        var hashValue: Int {
            return Int(upImage.width*upImage.height)
        }
        
        var upImage: CGImage
        var downImage: CGImage
        var upRect: CGRect
        var downRect: CGRect
    }
    
    func prepareTranlsate(rectangleResult: RectangleResult, minClip: Bool) -> TranslationPrepare {
        let topGap = self.frameResult.topGap!
        let bottomGap = self.frameResult.bottomGap!

        let rectangleLargestHeight: CGFloat = rectangleResult.largestRect!.height
        var upRectInLTC = CGRect(x: 0, y: 0, width: self.upImage.size.width, height: self.upImage.size.height - bottomGap)
        var downRectInLTC = CGRect(x: 0, y: topGap, width: self.upImage.size.width, height: self.upImage.size.height - topGap)
        var clipHeight:CGFloat
        if minClip {
            clipHeight = min(CGFloat(600), rectangleLargestHeight*self.upImage.size.height + 50)
        } else {
            clipHeight = max(CGFloat(600), rectangleLargestHeight*self.upImage.size.height + 50)
        }
        upRectInLTC.origin.y = upRectInLTC.origin.y + (upRectInLTC.height - clipHeight)
        upRectInLTC.size.height = clipHeight
        downRectInLTC.size.height = clipHeight
        
        let upRectImage = self.upImage.cgImage!.cropping(to: upRectInLTC)
        let downRectImage = self.downImage.cgImage!.cropping(to: downRectInLTC)

        return TranslationPrepare(upImage: upRectImage!, downImage: downRectImage!, upRect: upRectInLTC, downRect: downRectInLTC)
    }
    
    func detect(completeHandler: @escaping (CGFloat, CGFloat) -> Void) {
        if upImage.size != downImage.size {
            return completeHandler(0, 0)
        }
        
        getMiddleIntersection(completeHandler: completeHandler)
    }
}
