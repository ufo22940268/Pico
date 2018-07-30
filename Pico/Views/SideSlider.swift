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
    var delegate: EditDelegator?
    var arrow: UIImageView!
    var arrowAnimator: UIViewPropertyAnimator!
    
    override func awakeFromNib() {
        translatesAutoresizingMaskIntoConstraints = false

        layoutIfNeeded()
        switch position {
        case "left":
            button.roundCorners([.topRight, .bottomRight], radius: 15)
        case "right":
            button.roundCorners([.topLeft, .bottomLeft], radius: 15)
        default:
            break
        }

        let uiImage: UIImage? = position == "left" ? UIImage(named: "angle-double-left-solid") : UIImage(named: "angle-double-right-solid")
        
        arrow = UIImageView(image: uiImage)
        addSubview(arrow)
        arrow.isHidden = true
        arrow.translatesAutoresizingMaskIntoConstraints = false
        if position == "left" {
            arrow.leadingAnchor.constraint(equalTo: button.trailingAnchor, constant: ArrowConstants.gap).isActive = true
            arrow.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        } else if position == "right" {
            arrow.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -ArrowConstants.gap).isActive = true
            arrow.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        }
    }
    
    
    func updateSlider(midPoint: CGPoint) {
        topConstraint.constant = midPoint.y
        setNeedsLayout()
    }
    
    func setupAnimation() {
        let originFrame = arrow.frame
        arrowAnimator = UIViewPropertyAnimator(duration: ArrowConstants.animatorDuration, curve: .easeInOut, animations: {[weak self] in
            UIView.setAnimationRepeatCount(100000)
            UIView.setAnimationRepeatAutoreverses(true)
            if self != nil {
                let offsetX = self!.position == "left" ? -ArrowConstants.translate : ArrowConstants.translate
                self!.arrow.frame = self!.arrow.frame.offsetBy(dx: offsetX, dy: 0)
            }
        })
        arrowAnimator.addCompletion { (pos) in
            self.arrow.frame = originFrame
        }
    }
    
    @IBAction func onToggle(_ sender: UIButton) {
        if sender.isSelected {
            delegate?.editStateChanged(state: EditState.inactive)
            sender.isSelected = false
            stopAnimator()
        } else {
            delegate?.editStateChanged(state: EditState.editing(direction: position, seperatorIndex: nil))
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
