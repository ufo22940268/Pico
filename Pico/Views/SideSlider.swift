//
//  SideSlider.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/27.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class SideSlider: UIView, Slider {
    
    var placeholder: SliderPlaceholder!
    
    @objc var direction: String!

    @IBOutlet weak var button: SliderButton!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    weak var delegate: EditDelegator?
    var arrow: ArrowImage!
    var arrowAnimator: UIViewPropertyAnimator!
    
    override func awakeFromNib() {
        let uiImage: UIImage? = direction == "left" ? UIImage(named: "angle-double-left-solid") : UIImage(named: "angle-double-right-solid")
        
        arrow = ArrowImage(image: uiImage)
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
    
    func update(midPoint: CGPoint) {
        topConstraint.constant = midPoint.y
    }
    
    func updateScale(_ scale: CGFloat) {
        button.scale = scale
        arrow.scale = scale
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
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled else {
            return nil
        }
        
        for view in subviews.reversed() {
            var convertedPoint: CGPoint!
            convertedPoint = view.convert(point, from: self)
            if let v = view.hitTest(convertedPoint, with: event) {
                return v
            }
        }
        
        return nil
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
