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
    
    var upImages = [CGImage:CGFloat]()
    var downImage:CGImage!
    var frameResult: FrameDetectResult!
    var cropFrame:CGRect!
    var upImage:CGImage!
    
    fileprivate func generateUpImages(by divideCount: Int, _ cropRect: CGRect, _ upImage: UIImage) {
        let unitHeight = cropRect.height/CGFloat(divideCount/3)
        let preserveShift = CGFloat(0)
        
        Array(0...divideCount).forEach { i in
            var rect = cropRect
            rect.size.height = unitHeight
            rect.origin.y = rect.origin.y + (cropRect.height - unitHeight)
            
            var shift:CGFloat
            if i == 0 {
                shift = 0
            } else {
                shift = CGFloat(i - 1)*((cropRect.height - unitHeight - preserveShift)/CGFloat(divideCount - 1))
            }
            rect.origin.y = rect.origin.y - shift
            
            self.upImages[upImage.cropToCGImage(in: rect)] = shift
        }
    }
    
    init(upImage: UIImage, downImage: UIImage, frameResult: FrameDetectResult = FrameDetectResult.zero()) {
        let cropRect = CGRect(origin: CGPoint(x: 0, y: frameResult.topGap), size: CGSize(width: upImage.size.width, height: upImage.size.height - frameResult.topGap - frameResult.bottomGap))

        self.upImage = upImage.cropToCGImage(in: cropRect)
        
//        generateUpImages(by: 4, cropRect, upImage)
//        generateUpImages(by: 8, cropRect, upImage)
        generateUpImages(by: 10, cropRect, upImage)

        cropFrame = cropRect
        
        var downCropRect = cropRect
        self.downImage = downImage.cropToCGImage(in: downCropRect)
        
        self.frameResult = frameResult
    }
    
    func translation(regionHeight: CGFloat, upImage: CGImage, upImageShift: CGFloat, validOverlap:Bool = true,  complete: @escaping (CGFloat?, CGFloat?) -> Void) {
        let request = VNTranslationalImageRegistrationRequest(targetedCGImage: downImage, completionHandler: { (req, error) in
            if let first = req.results?.first, let obs = first as? VNImageTranslationAlignmentObservation {
                if obs.alignmentTransform.ty < 0 && abs(obs.alignmentTransform.tx) < 10  {
                    
                    let upShift:CGFloat = 0
                    let downShift = CGFloat(upImage.height) + obs.alignmentTransform.ty
                    
                    guard validOverlap else {
                        complete(upShift, downShift)
                        return
                    }
                    
                    let minDetectHeight = CGFloat(200)
                    let upDetectHeight = upImageShift
                    let downDetectHeight = downShift
                    
                    let detectHeight = min(upDetectHeight, downDetectHeight, minDetectHeight)
                    if detectHeight < minDetectHeight {
                        complete(nil, nil)
                        return
                    }
                    
                    let imageRegion = CGRect(origin: CGPoint.zero, size: self.cropFrame.size)
                    let upRegion = CGRect(origin: CGPoint(x: 0, y: imageRegion.height - upImageShift - downShift), size: CGSize(width: imageRegion.width, height: detectHeight))
                    let downRegion = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: imageRegion.width, height: detectHeight))
                    self.isRegionTheSame(upRegion: self.upImage.cropping(to: upRegion)!, downRegion: self.downImage.cropping(to: downRegion)!, complete: {same in
                        if same {
                            complete(upShift, downShift)
                        } else {
                            complete(nil, nil)
                        }
                    })
                } else {
                    complete(nil, nil)
                }
            }
        })
        
        do {
            try VNImageRequestHandler(cgImage: upImage, options: [:]).perform([request])
        } catch {
            print("VNImageRequestHandler error: \(error)")
            complete(nil, nil)
        }
    }
    
    func isRegionTheSame(upRegion:CGImage, downRegion:CGImage, complete:@escaping(Bool) -> Void) {
        let request = VNTranslationalImageRegistrationRequest(targetedCGImage: upRegion, options: [:], completionHandler: {(req, error) in
            let tolerance = CGFloat(2)
            if let obs = req.results?.first as? VNImageTranslationAlignmentObservation, abs(obs.alignmentTransform.ty) < tolerance && abs(obs.alignmentTransform.tx) == 0 {
                complete(true)
            } else {
                complete(false)
            }
        })
        
        do {
            try VNImageRequestHandler(cgImage: downRegion, options: [:]).perform([request])
        } catch {
            print("VNImageRequestHandler error in isRegionTheSame: \(error)")
            complete(false)
        }
    }
    
    func configureRectangleRequest(_ request: VNDetectRectanglesRequest) {
        request.maximumAspectRatio = 1.0
        request.minimumAspectRatio = 0.1
        request.quadratureTolerance = 45
        request.minimumConfidence = 0.1
        request.minimumSize = 0.01
        request.maximumObservations = 10
    }
    
    /// Detect rectangles in up image and down image.
    ///
    /// - Parameter complete: upRects is up image rectangles, downRects is down image rectangles.
    func findRectangles(complete: @escaping ([CGRect], [CGRect]) -> Void) {
        let group = DispatchGroup()
        var upRects = [CGRect]()
        
        group.enter()
        let upRequest = VNDetectRectanglesRequest { (req, error) in
            if let obsList = req.results {
                for obs in obsList {
                    if let obs = obs as? VNRectangleObservation {
                        let rect = obs.toRect(size: self.upImage.size).convertLBCToLTC(frameHeight: self.upImage.size.height)
                        upRects.append(rect)
                    }
                }
            }
            group.leave()
        }
        configureRectangleRequest(upRequest)
        try! VNImageRequestHandler(cgImage: upImage, options: [:]).perform([upRequest])

        var downRects = [CGRect]()
        group.enter()
        let downRequest = VNDetectRectanglesRequest { (req, error) in
            if let obsList = req.results {
                for obs in obsList {
                    if let obs = obs as? VNRectangleObservation {
                        let rect = obs.toRect(size: self.downImage.size).convertLBCToLTC(frameHeight: self.downImage.size.height)
                        downRects.append(rect)
                    }
                }
            }
            group.leave()
        }

        configureRectangleRequest(downRequest)
        try! VNImageRequestHandler(cgImage: downImage, options: [:]).perform([downRequest])
        
        group.notify(queue: .global()) {
            complete(upRects, downRects)
        }
    }
    
    func rectanglesWithSameSize(_ upRects: [CGRect], _ downRects: [CGRect]) -> [(CGRect, CGRect)] {
        var binds = [(CGRect, CGRect)]()
        for upRect in upRects {
            for downRect in downRects {
                if upRect.size.almostTheSameSize(downRect.size) {
                    binds.append((upRect, downRect))
                }
            }
        }
        
        
        //Sort by the sum of overlaps
        let upImageHeight = self.upImage.size.height
        binds.sort { (lbind, rbind) -> Bool in
            let lOverlap = (upImageHeight - lbind.0.maxY) + lbind.1.minY
            let rOverlap = (upImageHeight - rbind.0.maxY) + rbind.1.minY
            return lOverlap < rOverlap
        }
        return binds
    }
    
    func detect(completeHandler: @escaping (CGFloat, CGFloat) -> Void) {
        let heights = [CGFloat(1)]

        let group = DispatchGroup()
        var upOverlap:CGFloat? = nil
        var downOverlap:CGFloat? = nil
        
        //Detect all crop areas.
        for (upImage, shift) in (upImages.filter{$1 != 0}).sorted(by: {$0.value < $1.value}) {
            for regionHeight in heights {
                group.enter()
                translation(regionHeight: regionHeight, upImage: upImage, upImageShift: shift) { (up, down) in
                    if let down = down, let up = up {
                        let upPlusShift = up + shift
                        if downOverlap == nil  {
                            upOverlap = upPlusShift
                            downOverlap = down
                        }
                    }
                    group.leave()
                }
                group.wait()
                
                if downOverlap != nil {
                    break
                }
            }
            if downOverlap != nil {
                break
            }
        }
        
        //Detect edge scrop area.
        if downOverlap == nil {
            group.enter()
            let (image, shift) = upImages.filter {$1 == 0}.first!
            translation(regionHeight: 1, upImage: image, upImageShift: shift, validOverlap: false, complete: {up, down in
                if let down = down, let up = up {
                    let upPlusShift = up + shift
                    if downOverlap == nil  {
                        upOverlap = upPlusShift
                        downOverlap = down
                    }
                }
                group.leave()
            })
        }
        
        //Detect edge scrop area.
        if downOverlap == nil {
            group.enter()
            translation(regionHeight: 1, upImage: upImage, upImageShift: 0, validOverlap: false, complete: {up, down in
                if let down = down, let up = up {
                    let upPlusShift = up + 0
                    if downOverlap == nil  {
                        upOverlap = upPlusShift
                        downOverlap = down
                    }
                }
                group.leave()
            })
        }
        
        //Detect rectangle areas
        if downOverlap == nil {
            group.enter()
            findRectangles{(upRects: [CGRect], downRects: [CGRect]) in
                let rectGroup = DispatchGroup()
                for (upRect, downRect) in self.rectanglesWithSameSize(upRects, downRects) {
                    rectGroup.enter()
                    self.isRegionTheSame(upRegion: self.upImage.cropping(to: upRect)!, downRegion: self.downImage.cropping(to: downRect)!, complete: {same in
                        if same {
                            upOverlap = CGFloat(self.upImage.height) - upRect.maxY + upRect.height/2
                            downOverlap = downRect.minY + downRect.height/2
                        }
                        rectGroup.leave()
                    })
                    rectGroup.wait()
                    if downOverlap != nil {
                        break
                    }
                }
                rectGroup.notify(queue: .global(), execute: {
                    group.leave()
                })
            }
        }

        group.notify(queue: .main) {
            print("complete: \(upOverlap) \(downOverlap)")
            completeHandler(upOverlap ?? 0, downOverlap ?? 0)
        }
    }
}
 
