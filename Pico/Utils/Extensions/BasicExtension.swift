//
//  BasicExtends.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/11.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit


extension Float {
    var degreesToRadians: Float { return self * .pi / 180 }
    var radiansToDegrees: Float { return self * 180 / .pi }
}

extension CGSize {
    /// Height/Width
    var ratio : CGFloat {
        return height/width
    }
}

extension UIDevice {
    var isSimulator: Bool {
        #if IOS_SIMULATOR
        return true
        #else
        return false
        #endif
    }
}
