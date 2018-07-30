//
//  ComposeCell.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/3.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class ComposeCell: UIView, EditDelegator {
    
    @IBOutlet weak var image: UIImageView!
    
    var index: Int!
    var editState = EditState.inactive(fromDirections: nil)
    var onCellScrollDelegator: OnCellScroll!
    
    var originFrame: CGRect?
    
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
    }
    
    func editStateChanged(state: EditState) {
        editState = state
    }
    
    enum Position: Int {
        case above = -1, below = 1
    }
    
    //        above: -1
    //        below: 1
    static func getPositionToSeperator(editState: EditState, cellIndex: Int) -> Position? {
        if case .editing(let direction, let seperatorIndex) = editState {
            if direction == "vertical", let seperatorIndex = seperatorIndex {
                if cellIndex - seperatorIndex == 1 || cellIndex - seperatorIndex == -1 {
                    return Position.above
                } else if cellIndex - seperatorIndex == 0 {
                    return Position.below
                }
            }
        }
        
        return nil
    }
    
    func scrollY(_ position: ComposeCell.Position, _ translateY: CGFloat) {
        let shrink = CGFloat(position.rawValue) * translateY < 0
        
        let topConstraint = self.constraints.filter {$0.identifier == "top"}.first!
        let bottomConstraint = self.constraints.filter {$0.identifier == "bottom"}.first!
        let absTranslateY: CGFloat = abs(translateY)
        
        let deltaTranslateY = (shrink ? -1 : 1) * absTranslateY
        if case .above = position {
            let newContraint: CGFloat = bottomConstraint.constant + deltaTranslateY
            if newContraint < 0 {
                if !(shrink && frame.height - absTranslateY < 60) {
                    bottomConstraint.constant = newContraint
                    onCellScrollDelegator.onCellScroll(translate: Float(translateY), cellIndex: index, position: position)
                }
            }
        } else if case .below = position {
            let newContraint: CGFloat = topConstraint.constant - deltaTranslateY
            if newContraint > 0 {
                if !(shrink && frame.height - absTranslateY < 10) {
                    topConstraint.constant = newContraint
                    onCellScrollDelegator.onCellScroll(translate: Float(translateY), cellIndex: index, position: position)
                }
            }
        }
    }
    
    func convertPercentageToPT(percentage: CGFloat) -> CGFloat {
        return frame.height * percentage
    }
    
    func scrollDown(percentage: CGFloat) {
        scrollY(.above, convertPercentageToPT(percentage: percentage))
    }
    
    func scrollUp(percentage: CGFloat) {
        scrollY(.below, convertPercentageToPT(percentage: percentage))
    }

    func scrollVertical(_ sender: UIPanGestureRecognizer) {
        
        guard case .editing = editState else {
            return
        }
        
        let translate = sender.translation(in: self)
        
        guard let position = ComposeCell.getPositionToSeperator(editState: editState, cellIndex: index) else {
            return
        }
        
        let translateY = translate.y
        
        scrollY(position, translateY)

        sender.setTranslation(CGPoint.zero, in: image)
    }
    
    func scrollHorizontal(_ sender: UIPanGestureRecognizer, _ direction: String) {
        guard case .editing = editState else {
            return
        }

        let translate = sender.translation(in: self)
        let translateX = translate.x
        scrollX(translateX, direction)
    }
    
    func scrollX(_ translateX: CGFloat, _ direction: String) {
        guard translateX != 0 else {
            return
        }
  
        let shrink = (translateX > 0 && direction == "right") || (translateX < 0 && direction == "left")
        
        let activeConstraint = direction == "left" ? leadingConstraint! : trailingConstraint!
        var activeExpectConstraintConstant = activeConstraint.constant + (shrink ? -1 : 1)*abs(translateX)
        
        var calibratedTranslateX = translateX
        if activeExpectConstraintConstant < -frame.width {
            let calibrate = abs(activeExpectConstraintConstant) - frame.width
            calibratedTranslateX = calibratedTranslateX/abs(calibratedTranslateX)*(abs(calibratedTranslateX) - calibrate)
        } else if activeExpectConstraintConstant > 0 {
            let calibrate = activeExpectConstraintConstant
            calibratedTranslateX = calibratedTranslateX/abs(calibratedTranslateX)*(abs(calibratedTranslateX) - calibrate)
        }
        
        activeExpectConstraintConstant = activeConstraint.constant + (shrink ? -1 : 1)*abs(calibratedTranslateX)
        
        guard activeExpectConstraintConstant <= 0 else {
            return
        }
        
        if direction == "left" {
            let translateForActiveConstraint = (shrink ? -1 : 1)*abs(calibratedTranslateX)
            leadingConstraint.constant = leadingConstraint.constant + translateForActiveConstraint
            trailingConstraint.constant = trailingConstraint.constant - translateForActiveConstraint
        } else {
            let translateForActiveConstraint = (shrink ? -1 : +1)*abs(calibratedTranslateX)
            leadingConstraint.constant = leadingConstraint.constant - translateForActiveConstraint
            trailingConstraint.constant = trailingConstraint.constant + translateForActiveConstraint
        }
    }
    
    func setImage(uiImage: UIImage) {
        if let constraint = (self.constraints.filter { $0.identifier == "ratio" }.first) {
            self.removeConstraint(constraint)
        }
        
        let ratioConstraint: NSLayoutConstraint = NSLayoutConstraint(item: image, attribute: .width, relatedBy: .equal, toItem: image, attribute: .height, multiplier: uiImage.size.width/uiImage.size.height, constant: 0)
        ratioConstraint.identifier = "ratio"
        self.addConstraint(ratioConstraint)
        image.image = uiImage
    }
}
