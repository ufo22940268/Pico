//
//  UIViewExtension.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/20.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    func exportImageCache() -> UIImage? {
        UIGraphicsBeginImageContext(frame.size)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    func renderToCIImage() -> CIImage? {
        UIGraphicsBeginImageContext(frame.size)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let cache = CIImage(image: UIGraphicsGetImageFromCurrentImageContext()!)
        UIGraphicsEndImageContext()
        return cache
    }
}

extension NSLayoutConstraint {
    /**
     Change multiplier constraint
     
     - parameter multiplier: CGFloat
     - returns: NSLayoutConstraint
     */
    func setMultiplier(multiplier:CGFloat) -> NSLayoutConstraint {
        
        NSLayoutConstraint.deactivate([self])
        
        let newConstraint = NSLayoutConstraint(
            item: firstItem,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant)
        
        newConstraint.priority = priority
        newConstraint.shouldBeArchived = self.shouldBeArchived
        newConstraint.identifier = self.identifier
        
        NSLayoutConstraint.activate([newConstraint])
        return newConstraint
    }
}

