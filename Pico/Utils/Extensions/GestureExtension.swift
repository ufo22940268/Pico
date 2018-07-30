//
//  GestureExtension.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/30.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

public enum Direction: Int {
    case Up
    case Down
    case Left
    case Right
    
    public var isX: Bool { return self == .Left || self == .Right }
    public var isY: Bool { return !isX }
}

public extension UIPanGestureRecognizer {
    
    public var direction: Direction? {
        let velocityValue = velocity(in: view)
        let vertical = fabs(velocityValue.y) > fabs(velocityValue.x)
        switch (vertical, velocityValue.x, velocityValue.y) {
        case (true, _, let y) where y < 0: return .Up
        case (true, _, let y) where y > 0: return .Down
        case (false, let x, _) where x > 0: return .Right
        case (false, let x, _) where x < 0: return .Left
        default: return nil
        }
    }
}
