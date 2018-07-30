//
//  VNRectangleObserverExtension.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/26.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import Vision

extension VNRectangleObservation {
    func relativeTo(size: CGSize) -> String {
        return "x: \(bottomLeft.x*size.width)\t y: \(bottomLeft.y*size.height) \t width: \( (bottomRight.x - bottomLeft.x)*size.width) \t height: \((topLeft.y - bottomLeft.y)*size.height)"
    }
    
    func toRect(size: CGSize) -> CGRect {
        let originPoint = CGPoint(x: bottomLeft.x*size.width, y: bottomLeft.y*size.height)
        return CGRect(origin: originPoint, size: CGSize(width: (bottomRight.x - bottomLeft.x)*size.width, height: (topLeft.y - bottomLeft.y)*size.height))
    }
}
