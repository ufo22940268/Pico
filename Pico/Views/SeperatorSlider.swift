//
//  SeperatorSlider.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/4.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class SliderConstants {
    static let gap:CGFloat = 25.0
    static let width:CGFloat = 24
    static let height:CGFloat = 30
    static let translate:CGFloat = 10
    static let animatorDuration = 0.5
    
    static let buttonHeight = CGFloat(20)
}

class ArrowImage : UIImageView {
    
    var scale: CGFloat = 1.0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return super.intrinsicContentSize.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}


class SeperatorSlider: UIView, SliderSelectable {
    
    var aboveArrow: ArrowImage!
    var belowArrow: ArrowImage!
    var animations = [UIViewPropertyAnimator]()
    var index: Int!
    weak var editDelegator:EditDelegator?
    var validArrows = [UIImageView]()
    
    @objc var direction = "middle"
    @IBOutlet weak var button: SliderButton!
    @IBOutlet var buttonCenterXConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var middleTopCosntraint: NSLayoutConstraint!
    fileprivate func showAboveArrow() -> Bool {
        return ["bottom", "middle"].contains(direction)
    }
    
    fileprivate func showBelowArrow() -> Bool {
        return ["top", "middle"].contains(direction)
    }
    
    var directionEnum: SliderDirection!
    var arrowGapConstraints = [NSLayoutConstraint: ScalableConstant]()
    
    override func awakeFromNib() {
        
        directionEnum = SliderDirection.parse(direction: direction)
        
        buttonCenterXConstraint = button.centerXAnchor.constraint(equalTo: centerXAnchor)
        buttonCenterXConstraint.isActive = true
        
        aboveArrow = ArrowImage(image: UIImage(named: "angle-double-down-solid"))
        aboveArrow.tintColor = UIColor(named: "Slider")
        aboveArrow.isHidden = true
        aboveArrow.translatesAutoresizingMaskIntoConstraints = false
        belowArrow = ArrowImage(image: UIImage(named: "angle-double-up-solid"))
        belowArrow.tintColor = UIColor(named: "Slider")
        belowArrow.isHidden = true
        belowArrow.translatesAutoresizingMaskIntoConstraints = false
        
        if showBelowArrow() {
            setupBelowArrow(arrow: belowArrow)
        }

        if showAboveArrow() {
            setupAboveArrow(arrow: aboveArrow)
        }
                
        switch direction {
        case "top":
            button.roundCorners([.bottomLeft, .bottomRight], radius: SliderConstants.buttonHeight)
        case "middle":
            button.roundCorners([.bottomLeft, .bottomRight, .topLeft, .topRight], radius: SliderConstants.buttonHeight/2)
        case "bottom":
            button.roundCorners([.topLeft, .topRight], radius: SliderConstants.buttonHeight)
        default:
            break
        }
        
        addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0))
        backgroundColor = UIColor.yellow
        
        button.setup(direction: SliderDirection.parse(direction: direction))
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
    
    
    func updateSelectState(_ newSelectState: Bool) {
        button.isSelected = newSelectState
        
        if (button.isSelected) {
            enableScroll()
        } else {
            disableScroll()
        }
        
        var editState: EditState!
        if button.isSelected {
            editState = EditState.editing(direction: direction, seperatorIndex: index)
        } else {
            editState = EditState.inactive(fromDirections: direction)
        }
        
        editDelegator?.editStateChanged(state: editState)
    }
    
    @IBAction func onToggle(_ sender: UIButton) {
        let newSelectState: Bool = !button.isSelected
        updateSelectState(newSelectState)
    }
    
    func enableScroll() {
        setupAnimations()
        animations.forEach { (animator) in
            animator.startAnimation()
        }
        validArrows.forEach{$0.isHidden = false}
    }
    
    func disableScroll() {
        validArrows.forEach{$0.isHidden = true}
        animations.forEach { (animator) in
            animator.stopAnimation(false)
            animator.finishAnimation(at: .current)
        }
        animations.removeAll()
    }
    
    func updateButtonPosition(midPoint: CGPoint) {
        buttonCenterXConstraint.constant = (midPoint.x - bounds.midX)
    }
    
    func updateScale(_ scale: CGFloat) {
        button.scale = scale
        
        if directionEnum! == .middle {
            middleTopCosntraint.constant = -button.bounds.height/2
        }
        
        //Update scale for arrows
        aboveArrow.scale = scale
        belowArrow.scale = scale
        
        for (constraint, scaleConstant) in arrowGapConstraints {
            constraint.constant = scaleConstant.finalConstant(byScale: scale)
        }
    }
    
    fileprivate func setupAnimations() {
        //Above
        if showAboveArrow() {
            let aboveOriginFrame = self.aboveArrow.frame
            let animation = UIViewPropertyAnimator(duration: SliderConstants.animatorDuration, curve: .easeInOut) { [weak self] in
                UIView.setAnimationRepeatAutoreverses(true)
                UIView.setAnimationRepeatCount(100000)
                self?.aboveArrow.frame = self!.aboveArrow.frame.offsetBy(dx: 0, dy: SliderConstants.translate)
            }
            animation.addCompletion { (_) in
                self.aboveArrow.frame = aboveOriginFrame
            }
            animations.append(animation)
        }

        
        //Below
        if showBelowArrow() {
            let belowOriginFrame = self.belowArrow.frame
            let animation = UIViewPropertyAnimator(duration: SliderConstants.animatorDuration, curve: .easeInOut) { [weak self] in
                UIView.setAnimationRepeatAutoreverses(true)
                UIView.setAnimationRepeatCount(100000)
                self?.belowArrow.frame = self!.belowArrow.frame.offsetBy(dx: 0, dy: -SliderConstants.translate)
            }
            animation.addCompletion { (_) in
                self.belowArrow.frame = belowOriginFrame
            }
            animations.append(animation)
        }
    }
    
    fileprivate func setupAboveArrow(arrow: UIImageView) {
        addSubview(arrow)
        var gapConstant = ScalableConstant()
        gapConstant.constant = -SliderConstants.gap-15
        gapConstant.scale = 1
        let gap = NSLayoutConstraint(item: arrow, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: -SliderConstants.gap-15)
        arrowGapConstraints[gap] = gapConstant
        addConstraint(gap)
        addConstraint(NSLayoutConstraint(item: arrow, attribute: .centerX, relatedBy: .equal, toItem: button, attribute: .centerX, multiplier: 1, constant: 0) )
        validArrows.append(arrow)
        
    }
    
    fileprivate func setupBelowArrow(arrow: UIImageView) {
        addSubview(arrow)
        
        var gapConstant = ScalableConstant()
        gapConstant.constant = SliderConstants.gap
        gapConstant.scale = 1

        let gap = NSLayoutConstraint(item: arrow, attribute: .top, relatedBy: .equal, toItem: button, attribute: .bottom, multiplier: 1, constant: SliderConstants.gap)
        arrowGapConstraints[gap] = gapConstant
        addConstraint(gap)
        addConstraint(NSLayoutConstraint(item: arrow, attribute: .centerX, relatedBy: .equal, toItem: button, attribute: .centerX, multiplier: 1, constant: 0) )
        validArrows.append(arrow)
    }
}
