//
//  PreviewImage.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/17.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class PreviewCover: UIView {
    
    var selection:CGRect?
    
    func drawSelection(rect: CGRect) {
        self.selection = rect
        setNeedsDisplay()
    }
    
    func clearSelection() {
        self.selection = nil
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        if let selection = selection {
            let context = UIGraphicsGetCurrentContext()
            context?.setStrokeColor(UIColor.guidelinePink.cgColor)
            context?.addRect(selection)
            context?.strokePath()
        }
    }
}
