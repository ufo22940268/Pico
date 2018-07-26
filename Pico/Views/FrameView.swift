//
//  FrameView.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/24.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit

class FrameView: UIView {
    
    var frameRects = [CGRect]()
    var frameType: PreviewFrameType = .none
    
    override func awakeFromNib() {
        frameRects.append(CGRect(x: 0, y: 0, width: frame.width, height: 50))
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
     */
    override func draw(_ rect: CGRect) {
        guard frameType != .none else {
            return
        }
        
        // Drawing code
        let lineWidth = CGFloat(2)
        UIColor.white.setStroke()
        
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
