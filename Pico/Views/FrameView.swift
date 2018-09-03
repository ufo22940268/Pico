//
//  FrameView.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/24.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit

/// Deprecated
class FrameView: UIView {
    
    var frameRects = [CGRect]()
    var frameType: PreviewFrameType = .none
    var renderer: PreviewRenderer!
    
    override func awakeFromNib() {
        frameRects.append(CGRect(x: 0, y: 0, width: frame.width, height: 50))
        renderer = PreviewRenderer(imageScale: 1)
    }
    
    override func draw(_ rect: CGRect) {
        guard frameType != .none else {
            return
        }
        if !frameRects.isEmpty {
            let scale = rect.width/frameRects.first!.width
            renderer.drawFrameRects(rect: rect, frameType: frameType, frameRects: frameRects.map {$0.applying(CGAffineTransform(scaleX: scale, y: scale))})
        }
    }
    
}
