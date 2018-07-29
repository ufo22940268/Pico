//
//  SideSlider.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/27.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class SideSlider: UIView {
    
    @objc var position: String!

    @IBOutlet weak var button: UIButton!
    
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        translatesAutoresizingMaskIntoConstraints = false
        switch position {
        case "left":
            button.roundCorners([.topRight, .bottomRight], radius: 15)
        case "right":
            button.roundCorners([.topLeft, .bottomLeft], radius: 15)
        default:
            break
        }
    }
    
    func updateSlider(midPoint: CGPoint) {
        topConstraint.constant = midPoint.y
    }
}
