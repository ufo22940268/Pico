//
//  SeperatorSlider.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/4.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class ArrowConstants {
    static let gap:CGFloat = 25.0
    static let width:CGFloat = 24
    static let height:CGFloat = 30
    static let translate:CGFloat = 10
    static let animatorDuration = 0.5
}

class SeperatorSlider: UIView {
    
    var aboveArrow: UIImageView!
    var belowArrow: UIImageView!
    var animations = [UIViewPropertyAnimator]()
    var index: Int!
    var editDelegators:[EditDelegator] = [EditDelegator]()
    var validArrows = [UIImageView]()
    
    @objc var direction = "middle"
    @IBOutlet weak var button: UIButton!
    
    fileprivate func showAboveArrow() -> Bool {
        return ["bottom", "middle"].contains(direction)
    }
    
    fileprivate func showBelowArrow() -> Bool {
        return ["top", "middle"].contains(direction)
    }
    
    
    override func awakeFromNib() {
        aboveArrow = UIImageView(image: UIImage(named: "angle-double-down-solid"))
        aboveArrow.isHidden = true
        aboveArrow.translatesAutoresizingMaskIntoConstraints = false
        belowArrow = UIImageView(image: UIImage(named: "angle-double-up-solid"))
        belowArrow.isHidden = true
        belowArrow.translatesAutoresizingMaskIntoConstraints = false
        
        if  showBelowArrow() {
            setupBelowArrow(arrow: belowArrow)
        }

        if showAboveArrow() {
            setupAboveArrow(arrow: aboveArrow)
        }
        
        
        switch direction {
        case "top":
            button.roundCorners([.bottomLeft, .bottomRight], radius: 15)
        case "middle":            button.roundCorners([.bottomLeft, .bottomRight, .topLeft, .topRight], radius: 15)
        case "bottom":
            button.roundCorners([.topLeft, .topRight], radius: 15)
        default:
            break
        }
        
        addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0))
        backgroundColor = UIColor.yellow
    }
    
    func addEditDelegator(editDelegator: EditDelegator) {
        self.editDelegators.append(editDelegator)
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
    
    
    @IBAction func onToggle(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected

        if (sender.isSelected) {
            enableScroll()
        } else {
            disableScroll()
        }

        var editState: EditState!
        if sender.isSelected {
            editState = EditState.editing(direction: "vertical", seperatorIndex: index)
        } else {
            editState = EditState.inactive(fromDirections: "vertical")
        }
        
        editDelegators.forEach{ $0.editStateChanged(state: editState) }
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
    
    fileprivate func setupAnimations() {
        //Above
        if showAboveArrow() {
            let aboveOriginFrame = self.aboveArrow.frame
            let animation = UIViewPropertyAnimator(duration: ArrowConstants.animatorDuration, curve: .easeInOut) { [weak self] in
                UIView.setAnimationRepeatAutoreverses(true)
                UIView.setAnimationRepeatCount(100000)
                self?.aboveArrow.frame = self!.aboveArrow.frame.offsetBy(dx: 0, dy: ArrowConstants.translate)
            }
            animation.addCompletion { (_) in
                self.aboveArrow.frame = aboveOriginFrame
            }
            animations.append(animation)
        }

        
        //Below
        if showBelowArrow() {
            let belowOriginFrame = self.belowArrow.frame
            let animation = UIViewPropertyAnimator(duration: ArrowConstants.animatorDuration, curve: .easeInOut) { [weak self] in
                UIView.setAnimationRepeatAutoreverses(true)
                UIView.setAnimationRepeatCount(100000)
                self?.belowArrow.frame = self!.belowArrow.frame.offsetBy(dx: 0, dy: -ArrowConstants.translate)
            }
            animation.addCompletion { (_) in
                self.belowArrow.frame = belowOriginFrame
            }
            animations.append(animation)
        }
    }
    
    fileprivate func setupAboveArrow(arrow: UIImageView) {
        addSubview(arrow)
        addConstraint(NSLayoutConstraint(item: arrow, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: -ArrowConstants.gap-15))
        addConstraint(NSLayoutConstraint(item: arrow, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0) )
        addConstraint(NSLayoutConstraint(item: arrow, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: ArrowConstants.width))
        addConstraint(NSLayoutConstraint(item: arrow, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: ArrowConstants.height))
        validArrows.append(arrow)
    }
    
    fileprivate func setupBelowArrow(arrow: UIImageView) {
        addSubview(arrow)
        addConstraint(NSLayoutConstraint(item: arrow, attribute: .top, relatedBy: .equal, toItem: button, attribute: .bottom, multiplier: 1, constant: ArrowConstants.gap))
        addConstraint(NSLayoutConstraint(item: arrow, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0) )
        addConstraint(NSLayoutConstraint(item: arrow, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: ArrowConstants.width))
        addConstraint(NSLayoutConstraint(item: arrow, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: ArrowConstants.height))
        validArrows.append(arrow)
    }
}
