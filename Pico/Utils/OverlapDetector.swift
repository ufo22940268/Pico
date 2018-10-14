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
            
            self.upImages[upImage.cropImage(toRect: rect)] = shift
        }
    }
    
    init(upImage: UIImage, downImage: UIImage, frameResult: FrameDetectResult = FrameDetectResult.zero()) {
        let cropRect = CGRect(origin: CGPoint(x: 0, y: frameResult.topGap), size: CGSize(width: upImage.size.width, height: upImage.size.height - frameResult.topGap - frameResult.bottomGap))

        rawUpImage = upImage.cropImage(toRect: cropRect)
        
//        generateUpImages(by: 4, cropRect, upImage)
//        generateUpImages(by: 8, cropRect, upImage)
        generateUpImages(by: 10, cropRect, upImage)

        cropFrame = cropRect
        var downCropRect = cropRect
//        downCropRect.size.height = unitHeight
        self.downImage = downImage.cropImage(toRect: downCropRect)
        
        self.frameResult = frameResult
    }
    
    func translation(regionHeight: CGFloat, upImage: UIImage, upImageShift: CGFloat, validOverlap:Bool = true,  complete: @escaping (CGFloat?, CGFloat?) -> Void) {
        let request = VNTranslationalImageRegistrationRequest(targetedCGImage: downImage.cgImage!, completionHandler: { (req, error) in
            if let first = req.results?.first, let obs = first as? VNImageTranslationAlignmentObservation {
                print("alignTransform: \(obs.alignmentTransform)")
                if obs.alignmentTransform.ty < 0 && abs(obs.alignmentTransform.tx) < 200  {
                    
                    let upShift:CGFloat = 0
                    let downShift = upImage.size.height + obs.alignmentTransform.ty
                    
                    guard validOverlap else {
                        complete(upShift, downShift)
                        return
                    }
                    
                    let minDetectHeight = CGFloat(100)
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
        
        do {
            try VNImageRequestHandler(cgImage: upImage.cgImage!, options: [:]).perform([request])
        } catch {
            print("VNImageRequestHandler error: \(error)")
            complete(nil, nil)
        }
    }
    
    func isRegionTheSame(upRegion:CGImage, downRegion:CGImage, complete:@escaping(Bool) -> Void) {
        let request = VNTranslationalImageRegistrationRequest(targetedCGImage: upRegion, options: [:], completionHandler: {(req, error) in
            let tolerate = CGFloat(10)
            if let obs = req.results?.first as? VNImageTranslationAlignmentObservation, abs(obs.alignmentTransform.ty) < tolerate && abs(obs.alignmentTransform.tx) == 0 {
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
    
    func detect(completeHandler: @escaping (CGFloat, CGFloat) -> Void) {
        let heights = [CGFloat(1)]

        let group = DispatchGroup()
        var upOverlap:CGFloat? = nil
        var downOverlap:CGFloat? = nil
        
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

        group.notify(queue: .main) {
            print("complete: \(upOverlap) \(downOverlap)")
            completeHandler(upOverlap ?? 0, downOverlap ?? 0)
        }
    }
}
