//
//  UIImageExtension.swift
//  Pico
//
//  Created by Frank Cheng on 2018/9/7.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    func thumbnail() -> UIImage {
        let h = CGFloat(300)
        let w: CGFloat = size.width/size.height*h
        let newSize = CGSize(width: w, height: h)
        let image = UIGraphicsImageRenderer(size: newSize).image { context in
            self.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
        }
        return image
    }
}
