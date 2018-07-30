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
    case inactive
    case editing(direction: String, seperatorIndex: Int?)
}

class ComposeContainerView: UIStackView, EditDelegator, OnCellScroll {

    
    var editState = EditState.inactive
    var editDelegator: EditDelegator?
    var scrollDelegator: OnCellScroll?
    var cells = [ComposeCell]()
    var seperators = [SeperatorSlider]()
    
    var leftSlider: SideSlider!
    var rightSlider: SideSlider!

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
        seperator.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
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
        seperator.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
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
            updateSeperators()
        } else {
            seperators.forEach { $0.alpha = 0.0 }
        }
    }
    
    func updateSeperators() {
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
    
    func updateComposeCells(state: EditState) {
        cells.forEach {$0.editStateChanged(state: state)}
    }
 
    func editStateChanged(state: EditState) {
        self.editState = state
        updateSeperators()
        updateComposeCells(state: state)
        editDelegator?.editStateChanged(state: editState)    
    }
    
    func setEditDelegator(delegator: EditDelegator) {
        editDelegator = delegator
    }
}
