//
//  PreviewFrameDecorator.swift
//  Pico
//
//  Created by Frank Cheng on 2018/9/4.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class PreviewFrameDecorator {
    
    var image: CIImage!
    var frameType: PreviewFrameType!
    var frameWidth: CGFloat!
    
    enum FrameDecoratorDirection {
        case sider, top, bottom
    }

    init(image: CIImage, frameType: PreviewFrameType) {
        self.image = image
        self.frameType = frameType
        self.frameWidth = PreviewConstants.frameWidth*(image.extent.width/UIScreen.main.bounds.width)
    }
    
    func renderTopFrame() -> CIImage {
        var directions:[FrameDecoratorDirection]
        switch frameType! {
        case .full:
            directions = [.sider, .bottom, .top]
        case .seperator:
            directions = [.bottom, .top]
        case .none:
            directions = []
        default:
            directions = []
        }
        
        return renderFrame(for: image, directions: directions)
    }
    
    func renderNormalFrame() -> CIImage {
        var directions:[FrameDecoratorDirection]
        switch frameType! {
        case .full:
            directions = [.sider, .bottom]
        case .seperator:
            directions = [.bottom]
        case .none:
            directions = []
        default:
            directions = []
        }
        return renderFrame(for: image, directions: directions)
    }

    func renderFrame(for image: CIImage, directions: [FrameDecoratorDirection]) -> CIImage {
        var canvas = CIImage(color: CIColor(color: UIColor.white))
        
        var canvasWidth: CGFloat
        if directions.contains(.sider) {
            canvasWidth = image.extent.width + 2*frameWidth
        } else {
            canvasWidth = image.extent.width
        }
        
        var canvasHeight: CGFloat = image.extent.height
        if directions.contains(.top) {
            canvasHeight = canvasHeight + frameWidth
        }
        if directions.contains(.bottom) {
            canvasHeight = canvasHeight + frameWidth
        }
        
        let rect = CGRect(origin: image.extent.origin, size: CGSize(width: canvasWidth, height: canvasHeight))
        canvas = canvas.clampedToExtent().cropped(to: rect)
        canvas = image.transformed(by: CGAffineTransform(translationX: (canvasWidth - image.extent.width)/2, y: canvasHeight > image.extent.height ? frameWidth : 0)).composited(over: canvas)
        return canvas
    }
}
