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
    
    @objc var direction: String!

    @IBOutlet weak var button: UIButton!
    
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    var delegate: EditDelegator?
    var arrow: UIImageView!
    var arrowAnimator: UIViewPropertyAnimator!
    
    override func awakeFromNib() {
        translatesAutoresizingMaskIntoConstraints = false

        layoutIfNeeded()
        switch direction {
        case "left":
            button.roundCorners([.topRight, .bottomRight], radius: SliderConstants.buttonHeight/2)
        case "right":
            button.roundCorners([.topLeft, .bottomLeft], radius: SliderConstants.buttonHeight/2)
        default:
            break
        }

        let uiImage: UIImage? = direction == "left" ? UIImage(named: "angle-double-left-solid") : UIImage(named: "angle-double-right-solid")
        
        arrow = UIImageView(image: uiImage)
        addSubview(arrow)
        arrow.isHidden = true
        arrow.translatesAutoresizingMaskIntoConstraints = false
        if direction == "left" {
            arrow.leadingAnchor.constraint(equalTo: button.trailingAnchor, constant: SliderConstants.gap).isActive = true
//            arrow.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        } else if direction == "right" {
            arrow.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -SliderConstants.gap).isActive = true
//            arrow.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        }
    }
    
    
    func updateSlider(midPoint: CGPoint) {
        topConstraint.constant = midPoint.y
        setNeedsLayout()
    }
    
    func setupAnimation() {
        let originFrame = arrow.frame
        arrowAnimator = UIViewPropertyAnimator(duration: SliderConstants.animatorDuration, curve: .easeInOut, animations: {[weak self] in
            UIView.setAnimationRepeatCount(100000)
            UIView.setAnimationRepeatAutoreverses(true)
            if self != nil {
                let offsetX = self!.direction == "left" ? -SliderConstants.translate : SliderConstants.translate
                self!.arrow.frame = self!.arrow.frame.offsetBy(dx: offsetX, dy: 0)
            }
        })
        arrowAnimator.addCompletion { (pos) in
            self.arrow.frame = originFrame
        }
    }
    
    @IBAction func onToggle(_ sender: UIButton) {
        if sender.isSelected {
            delegate?.editStateChanged(state: EditState.inactive(fromDirections: direction))
            sender.isSelected = false
            stopAnimator()
        } else {
            delegate?.editStateChanged(state: EditState.editing(direction: direction, seperatorIndex: nil))
            sender.isSelected = true
            startAnimator()
        }
    }
    
    func startAnimator() {
        arrow.isHidden = false
        setupAnimation()
        arrowAnimator.startAnimation()
    }
    
    func stopAnimator() {
        arrow.isHidden = true
        if arrowAnimator != nil {
            arrowAnimator.stopAnimation(false)
            arrowAnimator.finishAnimation(at: .current)
        }
    }
    
    func addEditDelegator(editDelegator: EditDelegator) {
        delegate = editDelegator
    }
}
