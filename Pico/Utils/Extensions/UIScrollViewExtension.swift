//
//  UIScrollViewExtension.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/16.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

extension UIScrollView {
    
    func centerImage(imageViewHeight: CGFloat) {
        if imageViewHeight < frame.size.height {
            contentInset = UIEdgeInsets(top: (frame.size.height - imageViewHeight)/2, left: 0, bottom: 0, right: 0)
            layoutIfNeeded()
        }
    }
}

