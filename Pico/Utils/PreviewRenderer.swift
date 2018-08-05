//
//  PreviewRenderer.swift
//  Pico
//
//  Created by Frank Cheng on 2018/8/5.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class PreviewRenderer {
    
    var imageScale: CGFloat!
    var viewScale: CGFloat!
    
    init(imageScale: CGFloat) {
        self.imageScale = imageScale
        self.viewScale = imageScale*UIScreen.main.scale
    }
    
    func drawFrameRects(rect: CGRect, frameType: PreviewFrameType, frameRects: [CGRect], scale: CGFloat = 1) {
        // Drawing code
        let lineWidth = CGFloat(4*scale)
        UIColor.white.setStroke()
//        UIColor.red.setStroke()
        
        let path: UIBezierPath!
        if frameType == .seperator {
            path = UIBezierPath()
        } else {
            path = UIBezierPath(rect: rect)
            path.lineWidth = lineWidth*2
            path.stroke()
        }
        
        for rect in frameRects[0..<frameRects.count-1] {
            let fromPoint = CGPoint(x: 0, y: rect.maxY)
            let toPoint = CGPoint(x: rect.maxX, y: rect.maxY)
            path.move(to: fromPoint)
            path.addLine(to: toPoint)
            path.lineWidth = lineWidth
            path.stroke()
        }
    }
}
