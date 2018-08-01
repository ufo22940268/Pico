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
     *  - top
     *  - middle
     *  - bottom
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
    
    func maybeVertical() -> Bool {
        return ["top", "middle", "bottom"].contains(getDirection())
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
            seperators.forEach {$0.isHidden = true}
            leftSlider.isHidden = true
            leftSlider.isHidden = true
        }
    }
    
    fileprivate func updateSliderStateForSlideWhenEditChanged() {
        if case let .editing(direction, index) = editState {
            seperators.forEach { seperator in
                if seperator.index != index {
                    seperator.isHidden = true
                } else {
                    seperator.isHidden = false
                }
            }
        } else {
            seperators.forEach { seperator in
                seperator.isHidden = false
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
            leftSlider.isHidden = true
            rightSlider.isHidden = true
            seperators.first?.isHidden = true
            seperators.last?.isHidden = true
            
            getActiveSlider()?.isHidden = false
        }
    }
    
    func getActiveSlider() -> UIView? {
        guard case .editing = editState else {
            return nil
        }
        
        if sliderType == .crop {
            switch editState.getDirection() {
            case "left":
                return leftSlider
            case "right":
                return rightSlider
            case "top":
                return seperators.first
            case "bottom":
                return seperators.first
            default:
                break
            }
        } else if case .editing(_, let index) = editState, let seperatorIndex = index {
            return seperators[seperatorIndex]
        }
        return nil
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
    
    func exportSnapshot(callback: @escaping (UIImage) -> Void, wrapperBounds: CGRect) {
        let group = DispatchGroup()
        
        var imageMap = [Int: CIImage]()
        print("cell count", cells.count)
        for (index, cell) in cells.enumerated() {
            print("enter")
            group.enter()
            cell.exportSnapshot(callback: {img in
                print("leave")
                imageMap[index] = img
                group.leave()
            }, wrapperBounds: cell.convert(wrapperBounds, from: self))
        }
        
        group.notify(queue: .global(), execute: {
            print("images count", imageMap.count)
            
            let images = (imageMap.sorted(by: { (lhs, rhs) -> Bool in
                return lhs.key < rhs.key
            })).map {$0.value}
            let snapshotCI = CIImage.concateImages(images: images)
            let snapshot = snapshotCI.convertToUIImage()
            callback(snapshot)
        })
    }
}
