//
//  SideSlider.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/27.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class SideSlider: UIView, SliderSelectable {
    
    
    @objc var direction: String!

    @IBOutlet weak var button: SliderButton!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    weak var delegate: EditDelegator?
    var arrow: UIImageView!
    var arrowAnimator: UIViewPropertyAnimator!
    
    override func awakeFromNib() {
        translatesAutoresizingMaskIntoConstraints = false
        
        let uiImage: UIImage? = direction == "left" ? UIImage(named: "angle-double-left-solid") : UIImage(named: "angle-double-right-solid")
        
        arrow = UIImageView(image: uiImage)
        arrow.tintColor = UIColor(named: "Slider")
        addSubview(arrow)
        arrow.isHidden = true
        arrow.translatesAutoresizingMaskIntoConstraints = false
        if direction == "left" {
            arrow.leadingAnchor.constraint(equalTo: button.trailingAnchor, constant: SliderConstants.gap).isActive = true
            arrow.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        } else if direction == "right" {
            arrow.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -SliderConstants.gap).isActive = true
            arrow.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        }
        
        button.setup(direction: SliderDirection.parse(direction: direction))
    }
    
    func updateSlider(midPoint: CGPoint, transform: CGAffineTransform) {
        topConstraint.constant = midPoint.y
        button.scale = transform.a
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
        let newSelectState = !button.isSelected
        updateSelectState(newSelectState)
    }
    
    func updateSelectState(_ newSelectState: Bool) {
        if !newSelectState {
            delegate?.editStateChanged(state: EditState.inactive(fromDirections: direction))
            button.isSelected = newSelectState
            stopAnimator()
        } else {
            delegate?.editStateChanged(state: EditState.editing(direction: direction, seperatorIndex: nil))
            button.isSelected = newSelectState
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
