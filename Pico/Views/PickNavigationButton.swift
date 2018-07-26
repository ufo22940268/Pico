//
//  PickNavigationButton.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/11.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit
import Foundation

class PickNavigationButton: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
        
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var arrow: UIImageView!
    
    var isSelected = false
    
    func toggle(_ sender: PickNavigationButton) {
        var rotateDegree:Int
        if !isSelected {
            rotateDegree = 180
        } else {
            rotateDegree = -180
        }
        isSelected = !isSelected
        
        UIViewPropertyAnimator(duration: 0.15, curve: .linear, animations: {
            let radians = Float(rotateDegree).degreesToRadians
            self.arrow.transform = self.arrow.transform.rotated(by: CGFloat(radians))
        }).startAnimation()
    }
}

extension PickNavigationButton {
    func addOnClickListener(target: AnyObject, action: Selector) {
        let gr = UITapGestureRecognizer(target: target, action: action)
        gr.numberOfTapsRequired = 1
        addGestureRecognizer(gr)
    }
}
