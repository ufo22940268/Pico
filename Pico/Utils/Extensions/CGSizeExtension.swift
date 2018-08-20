//
//  CGSizeExtension.swift
//  Pico
//
//  Created by Frank Cheng on 2018/8/20.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

extension CGSize {
    
    func isScreenshot() -> Bool {
        return self == UIScreen.screens.first!.bounds.size.applying(CGAffineTransform(scaleX: UIScreen.main.scale, y: UIScreen.main.scale))
    }
}
