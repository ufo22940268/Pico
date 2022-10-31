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

class SliderPlaceholder: UIView {
    
    weak var rootView: UIView?
    var label: String!
    
    var frameInRootView: CGRect? {
        if ["top", "middle", "bottom"].contains(label) {
            if let container = self.superview, let wrapper = container.superview {
                let containerBounds = container.convert(wrapper.bounds.intersection(container.frame), from: wrapper)
                var newFrame = frame
                
                //Very strange. The minY of bottom placeholder is large than container bounds.
                if label == "bottom" {
                    newFrame = newFrame.offsetBy(dx: 0, dy: -0.1)
                }
                
                let rect = rootView?.convert(newFrame.intersection(containerBounds), from: self.superview)
                return rect
            } else {
                return nil
            }
        } else {
            return rootView?.convert(frame, from: self.superview)
        }
    }
        
    init(label: String) {
        super.init(frame: CGRect.zero)
        self.label = label
        translatesAutoresizingMaskIntoConstraints = false
        accessibilityHint = label
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
    
    var allSlider: [Slider] {
        return Array([seperators as [Slider], [leftSlider as Slider, rightSlider as Slider]].joined())
    }
    
    var sliderType: SliderType = .crop {
        willSet(newType) {
            if newType != sliderType {
                resetEditState()
            }
        }
    }
        
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
    
    func addTopSeperator(toView view: UIView) {
        let seperator = UINib(nibName: "Slider", bundle: nil).instantiate(withOwner: self, options: nil).map {$0 as! UIView}.filter {$0.restorationIdentifier == "top"}.first as! SeperatorSlider
        seperator.editDelegator = self
        
        let placeholder = SliderPlaceholder(label: "top")
        placeholder.rootView = view
        self.addArrangedSubview(placeholder)
        placeholder.heightAnchor.constraint(equalToConstant: 0).isActive = true
        seperator.placeholder = placeholder

        view.addSubview(seperator)

        seperator.index = seperators.count
        seperators.append(seperator)
    }
    
    func addMiddleSeperator(toView view: UIView) {
        let seperator = UINib(nibName: "Slider", bundle: nil).instantiate(withOwner: self, options: nil).first as! SeperatorSlider
        seperator.editDelegator = self
        
        let placeholder = SliderPlaceholder(label: "middle")
        placeholder.rootView = view
        self.addArrangedSubview(placeholder)
        placeholder.heightAnchor.constraint(equalToConstant: 0).isActive = true
        seperator.placeholder = placeholder
        
        view.addSubview(seperator)
        
        seperator.index = seperators.count
        seperators.append(seperator)
    }

    func addBottomSeperator(toView view: UIView) {
        let seperator = UINib(nibName: "Slider", bundle: nil).instantiate(withOwner: self, options: nil).map {$0 as! UIView}.filter {$0.restorationIdentifier == "bottom"}.first as! SeperatorSlider
        seperator.editDelegator = self
        
        let placeholder = SliderPlaceholder(label: "bottom")
        placeholder.rootView = view
        self.addArrangedSubview(placeholder)
        placeholder.heightAnchor.constraint(equalToConstant: 0).isActive = true
        seperator.placeholder = placeholder
        
        view.addSubview(seperator)
        
        seperator.index = seperators.count
        seperators.append(seperator)
    }
    
    func addLeftSeperator(toView view: UIView) {
        let seperator = UINib(nibName: "Slider", bundle: nil).instantiate(withOwner: self, options: nil).map {$0 as! UIView}.filter {$0.restorationIdentifier == "left"}.first as! SideSlider
        
        seperator.addEditDelegator(editDelegator: self)
        
        let placeholder = SliderPlaceholder(label: "left")
        placeholder.rootView = view
        if let wrapper = superview {
            wrapper.addSubview(placeholder)
            placeholder.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor).isActive = true
            placeholder.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 1.0).isActive = true
            placeholder.widthAnchor.constraint(equalToConstant: 0).isActive = true
            placeholder.topAnchor.constraint(equalTo: wrapper.topAnchor).isActive = true
        }
        seperator.placeholder = placeholder
        

        view.addSubview(seperator)

        leftSlider = seperator
    }
    
    func addRightSeperator(toView view: UIView) {
        let seperator = UINib(nibName: "Slider", bundle: nil).instantiate(withOwner: self, options: nil).map {$0 as! UIView}.filter {$0.restorationIdentifier == "right"}.first as! SideSlider
        seperator.addEditDelegator(editDelegator: self)
        
        let placeholder = SliderPlaceholder(label: "right")
        placeholder.rootView = view
        if let wrapper = superview {
            wrapper.addSubview(placeholder)
            placeholder.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor).isActive = true
            placeholder.heightAnchor.constraint(equalTo: wrapper.heightAnchor, multiplier: 1.0).isActive = true
            placeholder.widthAnchor.constraint(equalToConstant: 0).isActive = true
            placeholder.topAnchor.constraint(equalTo: wrapper.topAnchor).isActive = true
        }
        seperator.placeholder = placeholder

        view.addSubview(seperator)

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
    
    func updateSeperatorSliders(midPoint: CGPoint) {
        seperators.forEach { (slider) in
            slider.updateButtonPosition(midPoint: midPoint)
        }
    }
    
    func resetEditState() {
        for slider in allSlider {
            slider.updateSelectState(false)
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
        
        let targetWidth = CGFloat(cells.map {$0.imageEntity.asset.pixelWidth}.min { (c1, c2) -> Bool in
            c1 < c2
        }!)
        let queue = DispatchQueue(label: "com.bettycc.pico.compose.export")
        queue.async {
            for (index, cell) in self.cells.enumerated() {
                group.enter()
                cell.exportSnapshot(callback: {img in
                    autoreleasepool {
                        let calibratedImg = img.resetOffset().transformed(by: CGAffineTransform(scaleX: targetWidth/img.extent.width, y: targetWidth/img.extent.width))
                        if canvas == nil {
                            canvas = calibratedImg
                        } else {
                            canvas = CIImage.concateImages(images: [canvas!, calibratedImg], needScale: false)
                        }
                    }
                    group.leave()
                }, wrapperBounds: cell.convert(wrapperBounds, from: self), targetWidth: targetWidth)
                group.wait()
            }
            
            print("finish")
            
            group.notify(queue: .global(), execute: {
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
