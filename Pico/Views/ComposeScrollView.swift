//
//  ComposeScrollView.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/28.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit


class ComposeScrollView : UIScrollView {
    
    var topConstraints: NSLayoutConstraint!
    var bottomConstraints: NSLayoutConstraint!
    var containerWrapper: UIView!
    var container: UIView!
    
    override func updateConstraints() {
        if container.frame.height > frame.height {
            topConstraints.constant = 0
            bottomConstraints.constant = 0
        } else {
            let margin = frame.height - container.frame.height
            topConstraints.constant = margin/2
            bottomConstraints.constant = margin/2
        }
        super.updateConstraints()
    }
}
