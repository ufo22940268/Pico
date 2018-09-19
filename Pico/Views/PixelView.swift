//
//  PixelView.swift
//  Pico
//
//  Created by Frank Cheng on 2018/9/19.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class PixelView : UIImageView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    fileprivate func addPixelRects(rect: CGRect, in path: UIBezierPath) {
        let cropRect = rect.applying(CGAffineTransform(scaleX: bounds.width, y: bounds.height))
        path.append(UIBezierPath(rect: cropRect))
    }
    
    func updatePixelRects(_ rects: [CGRect]) {
        isHidden = rects.count == 0
        let path = UIBezierPath()
        rects.forEach{addPixelRects(rect: $0, in: path)}
        mask(withPath: path, inverse: false)
        setNeedsDisplay()
    }
}
