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
    
    var upImages = [UIImage:CGFloat]()
    var downImage:UIImage!
    var frameResult: FrameDetectResult!
    var cropFrame:CGRect!
    var rawUpImage:UIImage
    
    init(upImage: UIImage, downImage: UIImage, frameResult: FrameDetectResult = FrameDetectResult.zero()) {
        let cropRect = CGRect(origin: CGPoint(x: 0, y: frameResult.topGap), size: CGSize(width: upImage.size.width, height: upImage.size.height - frameResult.topGap - frameResult.bottomGap))

        rawUpImage = upImage.cropImage(toRect: cropRect)
        
        let divideCount = 20
        let unitHeight = cropRect.height/7
        let preserveShift = CGFloat(50)
        Array(1...divideCount).forEach { i in
            var rect = cropRect
            rect.size.height = unitHeight
            rect.origin.y = rect.origin.y + (cropRect.height - unitHeight)

            let shift: CGFloat = CGFloat(i - 1)*((cropRect.height - unitHeight - preserveShift)/CGFloat(divideCount - 1))
            rect.origin.y = rect.origin.y - shift

            self.upImages[upImage.cropImage(toRect: rect)] = shift
        }
        
        cropFrame = cropRect
        self.downImage = downImage.cropImage(toRect: cropRect)
        
//        self.upImages[upImage.cropImage(toRect: cropRect)] = 0
//        self.downImage = downImage.cropImage(toRect: cropRect)
        
        self.frameResult = frameResult
    }
    
    func translation(regionHeight: CGFloat, upImage: UIImage, upImageShift: CGFloat,  complete: @escaping (CGFloat?, CGFloat?) -> Void) {
        if upImageShift == 0 {
            complete(nil, nil)
            return
        }
        
        let request = VNTranslationalImageRegistrationRequest(targetedCGImage: downImage.cgImage!, completionHandler: { (req, error) in
            if let first = req.results?.first, let obs = first as? VNImageTranslationAlignmentObservation {
                if obs.alignmentTransform.ty < 0 && obs.alignmentTransform.tx == 0  {
                    print(upImage.size, self.downImage.size, obs.alignmentTransform)
                    
                    
                    let upShift:CGFloat = 0
                    let downShift = upImage.size.height - abs(obs.alignmentTransform.ty)
                    
                    let minDetectHeight = CGFloat(50)
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
                    print("up: \(upRegion) \t down: \(downRegion)")
                    self.isRegionTheSame(upRegion: self.rawUpImage.cropImage(toRect: upRegion).cgImage!, downRegion: self.downImage.cropImage(toRect: downRegion).cgImage!, complete: {same in
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
        
//        request.regionOfInterest = CGRect(x: 0, y: 0, width:1, height:regionHeight)
        try! VNImageRequestHandler(cgImage: upImage.cgImage!, options: [:]).perform([request])
    }
    
    func isRegionTheSame(upRegion:CGImage, downRegion:CGImage, complete:@escaping(Bool) -> Void) {
        let request = VNTranslationalImageRegistrationRequest(targetedCGImage: upRegion, options: [:], completionHandler: {(req, error) in
            let tolerate = CGFloat(50)
            if let obs = req.results?.first as? VNImageTranslationAlignmentObservation, abs(obs.alignmentTransform.ty) < tolerate && abs(obs.alignmentTransform.tx) < tolerate {
                complete(true)
            } else {
                complete(false)
            }
        })
        try! VNImageRequestHandler(cgImage: downRegion, options: [:]).perform([request])
    }
    
    func detect(completeHandler: @escaping (CGFloat, CGFloat) -> Void) {
        
//        let strideLength = 10
//        var heights = stride(from: 1, to: strideLength + 1, by: 1).map {CGFloat($0)/CGFloat(strideLength)}.reversed()
        
        let heights = [CGFloat(1)]

        let group = DispatchGroup()
        var upOverlap:CGFloat? = nil
        var downOverlap:CGFloat? = nil
        
        for (upImage, shift) in upImages.sorted(by: {$0.value < $1.value}) {
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

        group.notify(queue: .main) {
            print("complete: \(upOverlap) \(downOverlap)")
            completeHandler(upOverlap ?? 0, downOverlap ?? 0)
        }
    }
}
