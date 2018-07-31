//
//  ComposeContainerView.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/5.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit

protocol EditDelegator {
    func editStateChanged(state: EditState)
}

protocol OnCellScroll {
    func onCellScroll(translate: Float, cellIndex: Int, position: ComposeCell.Position)
}

enum EditState {
    case inactive(fromDirections: String?)
    /**
     * direction
     *  - vertical
     *  - left
     *  - right
    */
    case editing(direction: String, seperatorIndex: Int?)
    
    func getDirection() -> String {
        switch self {
        case .inactive(let fromDirections):
            return fromDirections ?? ""
        case .editing(let direction, _):
            return direction
        }
    }
}

class ComposeContainerView: UIStackView, EditDelegator, OnCellScroll {

    
    var editState = EditState.inactive(fromDirections: nil)
    var editDelegator: EditDelegator?
    var scrollDelegator: OnCellScroll?
    var cells = [ComposeCell]()
    var seperators = [SeperatorSlider]()
    
    var leftSlider: SideSlider!
    var rightSlider: SideSlider!
    
    var sliderType: SliderType = .crop

    func addImage(image: UIImage) {
        // Do any additional setup after loading the view.
        let view = UINib(nibName: "ComposeCell", bundle: nil).instantiate(withOwner: self, options: nil).first as! ComposeCell
        
        view.setImage(uiImage: image)
        view.index = cells.count
        view.restorationIdentifier = String(view.index)
        view.onCellScrollDelegator = self
        
        self.addArrangedSubview(view)
        
        cells.append(view)
    }
    
    func addTopSeperator() {
        let seperator = UINib(nibName: "Slider", bundle: nil).instantiate(withOwner: self, options: nil).map {$0 as! UIView}.filter {$0.restorationIdentifier == "top"}.first as! SeperatorSlider
        seperator.addEditDelegator(editDelegator: self)
        self.addArrangedSubview(seperator)

        seperator.index = seperators.count
        seperators.append(seperator)
    }
    
    func addSeperator() {
        let seperator = UINib(nibName: "Slider", bundle: nil).instantiate(withOwner: self, options: nil).first as! SeperatorSlider
        seperator.addEditDelegator(editDelegator: self)
        self.addArrangedSubview(seperator)
        
        seperator.index = seperators.count
        seperators.append(seperator)
    }

    func addBottomSeperator() {
        let seperator = UINib(nibName: "Slider", bundle: nil).instantiate(withOwner: self, options: nil).map {$0 as! UIView}.filter {$0.restorationIdentifier == "bottom"}.first as! SeperatorSlider
        seperator.addEditDelegator(editDelegator: self)
        self.addArrangedSubview(seperator)
        
        seperator.index = seperators.count
        seperators.append(seperator)
    }
    
    func addLeftSeperator() {
        let seperator = UINib(nibName: "Slider", bundle: nil).instantiate(withOwner: self, options: nil).map {$0 as! UIView}.filter {$0.restorationIdentifier == "left"}.first as! SideSlider
        self.addSubview(seperator)
        let topConstraint = seperator.topAnchor.constraint(equalTo: topAnchor)
        topConstraint.priority = .defaultHigh
        topConstraint.isActive = true
        let bottomConstraint = seperator.bottomAnchor.constraint(equalTo: bottomAnchor)
        bottomConstraint.priority = .defaultHigh
        bottomConstraint.isActive = true
        
        seperator.addEditDelegator(editDelegator: self)
        
        leftSlider = seperator
    }
    
    func addRightSeperator() {
        let seperator = UINib(nibName: "Slider", bundle: nil).instantiate(withOwner: self, options: nil).map {$0 as! UIView}.filter {$0.restorationIdentifier == "right"}.first as! SideSlider
        self.addSubview(seperator)
        let topConstraint = seperator.topAnchor.constraint(equalTo: topAnchor)
        topConstraint.priority = .defaultHigh
        topConstraint.isActive = true
        let bottomConstraint = seperator.bottomAnchor.constraint(equalTo: bottomAnchor)
        bottomConstraint.priority = .defaultHigh
        bottomConstraint.isActive = true
        
        seperator.addEditDelegator(editDelegator: self)
        
        rightSlider = seperator
    }
    
    func onCellScroll(translate: Float, cellIndex: Int, position: ComposeCell.Position) {
        scrollDelegator?.onCellScroll(translate: translate, cellIndex: cellIndex, position: position)
    }

    func showSeperators(show: Bool) {
        if show {
            updateSlidersWhenEditChanged()
        } else {
            seperators.forEach { $0.alpha = 0.0 }
        }
    }
    
    fileprivate func updateSliderStateForSlideWhenEditChanged() {
        if case let .editing(direction, index) = editState {
            seperators.forEach { seperator in
                if seperator.index != index {
                    seperator.isUserInteractionEnabled = false
                    seperator.alpha = 0.0
                } else {
                    seperator.isUserInteractionEnabled = true
                    seperator.alpha = 1.0
                }
            }
        } else {
            seperators.forEach { seperator in
                seperator.alpha = 1.0
                seperator.isUserInteractionEnabled = true
            }
        }
    }
    
    fileprivate func updateSliderStateForCropWhenEditChanged() {
        switch editState {
        case .inactive:
            leftSlider.isHidden = false
            rightSlider.isHidden = false
            seperators.first?.isHidden = false
            seperators.last?.isHidden = false
        case .editing:
            if editState.getDirection() == "left" {
                leftSlider.isHidden = false
                rightSlider.isHidden = true
            } else {
                leftSlider.isHidden = true
                rightSlider.isHidden = false
            }
            seperators.first?.isHidden = true
            seperators.last?.isHidden = true
        }
    }
    
    func updateSlidersWhenEditChanged() {
        if sliderType == .crop {
            updateSliderStateForCropWhenEditChanged()
        } else {
            updateSliderStateForSlideWhenEditChanged()
        }
    }
    
    func updateComposeCells(state: EditState) {
        cells.forEach {$0.editStateChanged(state: state)}
    }
 
    func editStateChanged(state: EditState) {
        self.editState = state
        updateSlidersWhenEditChanged()
        updateComposeCells(state: state)
        editDelegator?.editStateChanged(state: editState)    
    }
    
    func setEditDelegator(delegator: EditDelegator) {
        editDelegator = delegator
    }
    
    func updateVerticalSliderButtons(midPoint: CGPoint) {
        seperators.forEach { (slider) in
            slider.updateButtonPosition(midPoint: midPoint)
        }
    }
    
    /// Call after slider type changed
    func updateSliderType() {
        if sliderType == .crop {
            seperators[1..<seperators.count - 1].forEach {$0.isHidden = true}
            seperators.first?.isHidden = false
            seperators.last?.isHidden = false
            leftSlider.isHidden = false
            rightSlider.isHidden = false
        } else if sliderType == .slide {
            seperators[0..<seperators.count].forEach {$0.isHidden = false}
            leftSlider.isHidden = true
            rightSlider.isHidden = true
        }
    }
}
