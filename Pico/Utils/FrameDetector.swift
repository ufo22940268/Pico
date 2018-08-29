//
//  FrameDetector.swift
//  Pico
//
//  Created by Frank Cheng on 2018/8/29.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

struct FrameDetectResult {
    let topGap: CGFloat!
    let bottomGap: CGFloat!
    
    static func zero() -> FrameDetectResult {
        return FrameDetectResult(topGap: 0, bottomGap: 0)
    }
}

class FrameDetector {
    
    var upImage: UIImage!
    var downImage: UIImage!
    var upRGB: RGBAImage!
    var downRGB: RGBAImage!
    
    let invalidPercentThreshold = Float(0.1)
    

    init(upImage: UIImage, downImage: UIImage) {
        self.upImage = upImage
        self.downImage = downImage
        self.upRGB = RGBAImage(image: upImage)
        self.downRGB = RGBAImage(image: downImage)
    }
    
    func getTopGap() -> CGFloat {
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
        return CGFloat(untilLine)
    }
    
    func getBottomGap() -> CGFloat {
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
        return CGFloat(overlapHeight)
    }
    
    func detect() -> FrameDetectResult {
        return FrameDetectResult(topGap: getTopGap(), bottomGap: getBottomGap())
    }
}
