//
//  CGRectExtensions.swift
//  Pico
//
//  Created by Frank Cheng on 2018/8/10.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

extension CGRect {
    
    func extentWidth() -> CGFloat {
        return width - origin.x
    }
    
    func extentHeight() -> CGFloat {
        return height - origin.y
    }
    
    
    /// Convert left top coordinate to left bottom coordinate
    ///
    /// - Parameter frameHeight: height of frame
    mutating func convertLTCToLBC(frameHeight: CGFloat) -> CGRect {
        self.origin.y = frameHeight - self.origin.y - self.height
        return self
    }
}
