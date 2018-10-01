//
//  ComposeContainerView.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/5.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit

protocol EditDelegator: class {
    func editStateChanged(state: EditState)
}

protocol OnCellScroll: class {
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
    weak var editDelegator: EditDelegator?
    weak var scrollDelegator: OnCellScroll?
    var cells = [ComposeCell]()
    var seperators = [SeperatorSlider]()
    
    var leftSlider: SideSlider!
    var rightSlider: SideSlider!
    
    var sliderType: SliderType = .crop

    func addImage(imageEntity: Image) {
        // Do any additional setup after loading the view.
        let view = UINib(nibName: "ComposeCell", bundle: nil).instantiate(withOwner: self, options: nil).first as! ComposeCell
        
        view.setup(image: imageEntity)
        view.index = cells.count
        view.restorationIdentifier = String(view.index)
        view.onCellScrollDelegator = self
        
        self.addArrangedSubview(view)
        
        cells.append(view)        
    }
    
    func addTopSeperator() {
        let seperator = UINib(nibName: "Slider", bundle: nil).instantiate(withOwner: self, options: nil).map {$0 as! UIView}.filter {$0.restorationIdentifier == "top"}.first as! SeperatorSlider
        seperator.editDelegator = self
        self.addArrangedSubview(seperator)

        seperator.index = seperators.count
        seperators.append(seperator)
    }
    
    func addSeperator() {
        let seperator = UINib(nibName: "Slider", bundle: nil).instantiate(withOwner: self, options: nil).first as! SeperatorSlider
        seperator.editDelegator = self
        self.addArrangedSubview(seperator)
        
        seperator.index = seperators.count
        seperators.append(seperator)
    }

    func addBottomSeperator() {
        let seperator = UINib(nibName: "Slider", bundle: nil).instantiate(withOwner: self, options: nil).map {$0 as! UIView}.filter {$0.restorationIdentifier == "bottom"}.first as! SeperatorSlider
        seperator.editDelegator = self
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
            seperators.forEach {$0.hideAndDisable(true)}
            leftSlider.hideAndDisable(true)
            rightSlider.hideAndDisable(true)
        }
    }
    
    func showActiveSeperator() {
        getActiveSlider()?.hideAndDisable(false)
    }
    
    fileprivate func updateSliderStateForSlideWhenEditChanged() {
        if case let .editing(_, index) = editState {
            seperators.forEach { seperator in
                if seperator.index != index {
                    seperator.hideAndDisable(true)
                } else {
                    seperator.hideAndDisable(false)
                }
            }
        } else {
            seperators.forEach { seperator in
                seperator.hideAndDisable(false)
            }
        }
    }
    
    fileprivate func updateSliderStateForCropWhenEditChanged() {
        switch editState {
        case .inactive:
            leftSlider.hideAndDisable(false)
            rightSlider.hideAndDisable(false)
            seperators.first?.hideAndDisable(false)
            seperators.last?.hideAndDisable(false)
        case .editing:
            leftSlider.hideAndDisable(true)
            rightSlider.hideAndDisable(true)
            seperators.first?.hideAndDisable(true)
            seperators.last?.hideAndDisable(true)
            
            getActiveSlider()?.hideAndDisable(false)
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
                return seperators.last
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
        } else if sliderType == .slide {
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
    
    func updateSeperatorSliders(midPoint: CGPoint, transform: CGAffineTransform) {
        seperators.forEach { (slider) in
            slider.updateButtonPosition(midPoint: midPoint)
            slider.updateScale(transform.a)
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
        } else {
            seperators[1..<seperators.count - 1].forEach {$0.isHidden = true}
            seperators.first?.isHidden = true
            seperators.last?.isHidden = true
            leftSlider.isHidden = true
            rightSlider.isHidden = true
        }
    }
    
    func exportSnapshot(callback: @escaping (UIImage) -> Void, wrapperBounds: CGRect) {
        let group = DispatchGroup()
        var canvas: CIImage? = nil
        
        let targetWidth = cells.map {$0.imageEntity.asset.pixelWidth}.min { (c1, c2) -> Bool in
            c1 < c2
        }
        let queue = DispatchQueue(label: "comjjj")
        queue.async {
            for (index, cell) in self.cells.enumerated() {
                group.enter()
                cell.exportSnapshot(callback: {img in
                    autoreleasepool {
                        if canvas == nil {
                            canvas = img
                        } else {
                            canvas = CIImage.concateImages(images: [canvas!, img], needScale: false)
                        }
                    }
                    group.leave()
                }, wrapperBounds: cell.convert(wrapperBounds, from: self), targetWidth: CGFloat(targetWidth!))
                group.wait()
            }
            
            print("finish")
            
            group.notify(queue: .global(), execute: {
                print("quitttttttttttttttt")
                let snapshot = canvas!.convertToUIImage()
                callback(snapshot)
            })
        }
    }
}


extension ComposeContainerView : RecycleList {
    
    func getCells() -> [RecycleCell] {
        return cells
    }
}
