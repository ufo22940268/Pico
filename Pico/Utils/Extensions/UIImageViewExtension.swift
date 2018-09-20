//
//  UIImageViewExtension.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/16.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

extension UIImageView {
    func setImageAndRatio(uiImage: UIImage) {
        image = uiImage
        let ratio: CGFloat = uiImage.size.width/uiImage.size.height
        addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: self, attribute: .height, multiplier: ratio, constant: 0))
    }    
}
