//
//  ComposeController.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/3.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit

enum SliderType {
    case crop, slide
}

class ComposeController: UIViewController, EditDelegator, OnCellScroll {
    
    @IBOutlet weak var container: ComposeContainerView!
    @IBOutlet weak var scroll: UIScrollView!
    @IBOutlet weak var containerWrapper: UIView!
    
    @IBOutlet var topConstraint: NSLayoutConstraint!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var containerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var containerTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var containerWrapperLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var containerWrapperTrailingConstraint: NSLayoutConstraint!

    var containerLeadingConstraintConstant = ScalableConstant()
    var containerTrailingConstraintConstant = ScalableConstant()

    @IBOutlet var slideTypeItems: [UIBarButtonItem]!
    
    let minContainerWidth = CGFloat(230)
    let maxContainerWidth = UIScreen.main.bounds.width
    var lastScale = CGFloat(1.0)
    
    var editState: EditState = .inactive(fromDirections: nil)
    var panView: ComposeCell!
    
    /// Useless, remove in future.
    var loadedImages:[Image]!
    var loadedUIImages: [UIImage] = [UIImage]()
    
    @IBOutlet weak var containerWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet var containerWrapperCenterXConstraint: NSLayoutConstraint!
    @IBOutlet var panGesture: UIPanGestureRecognizer!
    
    var maskCenterXConstraint: NSLayoutConstraint!
    var maskHeightToContainerWrapperConstraint: NSLayoutConstraint!
    var maskCenterXToContainerConstraint: NSLayoutConstraint!
    var maskCenterXToContainerWrapperConstraint: NSLayoutConstraint!
    
    enum ConcatenateType {
        case screenshot
        case normal
        case movie
    }
    
    var type: ConcatenateType!

    fileprivate func concateScreenshot(_ uiImages: ([UIImage?])) {
        let dispatchGroup = DispatchGroup()
        for index in 0..<uiImages.count - 1 {
            let upImage = uiImages[index]
            let downImage = uiImages[index + 1]
            dispatchGroup.enter()
            OverlapDetector(upImage: upImage!, downImage: downImage!).detect {upOverlap, downOverlap in
                DispatchQueue.main.async {
                    if upOverlap > 0 && downOverlap > 0 {
                        let imageHeight = uiImages[0]!.size.height
                        print(index, "up", upOverlap, "down", downOverlap)
                        self.container.cells[index].scrollDown(percentage: upOverlap/imageHeight)
                        self.container.cells[index + 1].scrollUp(percentage: -downOverlap/imageHeight)
                    }
                    dispatchGroup.leave()
                }
            }

            dispatchGroup.notify(queue: .main) {                
                self.resetGapToContainer()
            }
        }
    }
    
    fileprivate func configureUIImages(_ uiImages: ([UIImage?])) {
        self.container.addTopSeperator()
        
        self.container.addImage(image: uiImages.first!!, imageEntity: loadedImages.first!)
        
        for (index, image) in uiImages[1..<uiImages.count].enumerated() {
            self.container.addSeperator()
            self.container.addImage(image: image!, imageEntity: loadedImages[index + 1])
        }
        
        self.container.addBottomSeperator()
        
        self.container.addLeftSeperator()
        self.container.leftSlider.leadingAnchor.constraint(equalTo: containerWrapper.leadingAnchor).isActive = true
        self.container.addRightSeperator()
        self.container.rightSlider.trailingAnchor.constraint(equalTo: containerWrapper.trailingAnchor).isActive = true
        
        self.container.subviews.filter{$0.isKind(of: SeperatorSlider.self)}.forEach {self.container.bringSubview(toFront: $0)}
        self.container.subviews.filter{$0.isKind(of: SideSlider.self)}.forEach {
            self.container.bringSubview(toFront: $0)            
        }

        switch self.type {
        case .screenshot:
            self.concateScreenshot(uiImages)
            self.navigationItem.title = "长截图"
        case .movie:
            MovieConcate(cells: self.container.cells, images: uiImages).scrollCells()
            self.navigationItem.title = "电影截图"
        default:
            self.navigationItem.title = "竖向拼接"
        }
        
        scroll.layoutIfNeeded()
        self.resetGapToContainer()
        
        updateSideSliderButtons()

        container.updateSliderType()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        container.sliderType = .slide
        toolbarItems?.first?.setBackgroundImage(UIImage(named: "crop-alt-solid-fade"), for: .highlighted, barMetrics: .default)
        
        container.setEditDelegator(delegator: self)
        container.scrollDelegator = self
        
        scroll.delegate = self
        
        if loadedImages == nil {
            type = .screenshot
            let sampleImages: [UIImage?] = [UIImage(named: "IMG_3146"), UIImage(named: "IMG_3147")]
            loadedImages = sampleImages.map {ImageMocker(image: $0!)}
            self.configureUIImages(sampleImages)
        } else if loadedImages.count >= 2 {
            loadedImages = loadedUIImages.map {ImageMocker(image: $0)}
            self.configureUIImages(loadedUIImages)
        }
        
    }
    
    @IBAction func download(_ sender: UIBarButtonItem) {
        sender.isEnabled = false
        let rect: CGRect = self.container.convert(self.containerWrapper.bounds, from: self.containerWrapper)
        let shareManager: ShareManager = ShareManager(viewController: self)
        shareManager.startSavingPhoto()
        self.container.exportSnapshot(callback: {snapshot in
            DispatchQueue.main.async {
                sender.isEnabled = true
                shareManager.saveToPhoto(image: snapshot)
            }
        }, wrapperBounds: rect)
    }
    
    fileprivate func onScrollVertical(_ sender: UIPanGestureRecognizer) {
        if case .began = sender.state {
            let containerPoint: CGPoint = sender.location(in: container)
            let hitViews = container.cells.filter {
                $0.point(inside: $0.convert(containerPoint, from: container), with: nil)
            }
            
            if hitViews.count == 1 {
                if let cell = findScrollCell(hitView: hitViews.first!) {
                    panView = cell
                }
            } else {
                print("should only hit one cell view")
            }
            
        } else if case .changed = sender.state {
            panView.scrollVertical(sender)
            container.showSeperators(show: false)
        } else if sender.state == .ended {
            container.showSeperators(show: true)
        }
    }
    
    fileprivate func onScrollHorizontal(_ sender: UIPanGestureRecognizer, _ direction: String) {
        if sender.state == .changed {
            guard case .editing = editState else {
                return
            }
            
            let translate = sender.translation(in: container)
            let translateX = translate.x
            
            guard translateX != 0 else {
                return
            }
            
            let shrink = (translateX > 0 && direction == "right") || (translateX < 0 && direction == "left")
            
            var calibratedTranslateX = translateX

            /// Move container
            var translateForActiveConstraint: CGFloat!
            var calibrateDirection: CGFloat!
            
            let activeConstraint = direction == "left" ? containerLeadingConstraint! : containerTrailingConstraint!
            var activeConstantCopy = direction == "left" ? containerLeadingConstraintConstant : containerTrailingConstraintConstant
            let alternativeConstantCopy = direction == "left" ? containerTrailingConstraintConstant : containerLeadingConstraintConstant
            if direction == "left" {
                calibrateDirection = (shrink ? -1 : 1)
            } else {
                calibrateDirection = (shrink ? 1 : -1)
            }
            translateForActiveConstraint = calibrateDirection*abs(calibratedTranslateX)
            
            let targetConstant = activeConstantCopy.addConstant(delta: translateForActiveConstraint)

            if (direction == "left" && targetConstant > 0) || (direction == "right" && targetConstant < 0) {
                //TODO Calibrate left right translate
//                let delta = abs(targetConstant)
//                calibratedTranslateX = calibratedTranslateX/abs(calibratedTranslateX) * (abs(calibratedTranslateX) - delta)
                return
            } else if abs(targetConstant) + abs(alternativeConstantCopy.finalConstant()) > container.frame.width {
                let delta = abs(targetConstant) + abs(alternativeConstantCopy.finalConstant()) - container.frame.width
                calibratedTranslateX = calibratedTranslateX/abs(calibratedTranslateX)*(abs(calibratedTranslateX) - delta)
            } else if container.frame.width - abs(targetConstant) - abs(alternativeConstantCopy.finalConstant()) < 30 {
                return
            }
            
            if direction == "left" {
                activeConstraint.constant = containerLeadingConstraintConstant.addConstant(delta: calibrateDirection*abs(calibratedTranslateX))
            } else {
                activeConstraint.constant = containerTrailingConstraintConstant.addConstant(delta: calibrateDirection*abs(calibratedTranslateX))
            }
            
            /// Update container wrapper
            switch direction {
            case "left":
                containerWrapperTrailingConstraint.constant = containerWrapperTrailingConstraint.constant + (shrink ? 1 : -1)*abs(calibratedTranslateX)
            case "right":
                containerWrapperLeadingConstraint.constant = containerWrapperLeadingConstraint.constant + (shrink ? 1 : -1)*abs(calibratedTranslateX)
            default:
                break
            }
            
            updateSeperatorSliderButtons()
            
            sender.setTranslation(CGPoint.zero, in: container)
        }
    }
    
    @IBAction func onScroll(_ sender: UIPanGestureRecognizer) {
        guard case .editing = editState else {
            return
        }
        
        if case .editing(let direction, _) = editState {
            if editState.maybeVertical() {
                onScrollVertical(sender)
            } else {
                onScrollHorizontal(sender, direction)
            }
        }
        
        updateAfterWrapperResize()
    }
    
    func findScrollCell(hitView: UIView) -> ComposeCell? {
        let cellIndex = container.cells.enumerated().filter {$0.element == hitView}.first!.offset
        if case .editing(let direction, let seperatorIndex) = editState {
            if let seperatorIndex = seperatorIndex, editState.maybeVertical() {
                if cellIndex < seperatorIndex {
                    return container.cells[seperatorIndex - 1]
                } else {
                    return container.cells[seperatorIndex]
                }
            }
        }
        
        return nil
    }
    
    func getContainerScale() -> CGFloat {
        return container.bounds.width/maxContainerWidth
    }
    
    func onCellScroll(translate: Float, cellIndex: Int, position: ComposeCell.Position) {
        let scale = getContainerScale()
        if case .above = position {
            topConstraint.constant = topConstraint.constant + CGFloat(translate)*scale
        } else if case .below = position {
            bottomConstraint.constant = bottomConstraint.constant - CGFloat(translate)*scale
        }
    }

    fileprivate func resetGapToContainer() {
        var topDistance = topConstraint.constant
        var bottomDistance = bottomConstraint.constant
        
        var topInset = CGFloat(0)
        var bottomInset = CGFloat(0)
        let containerHeight = max(container.frame.height, container.frame.height*(minContainerWidth/container.frame.width))
        if containerHeight < scroll.frame.height {
            let halfGap = (scroll.frame.height - containerHeight)/2
            topDistance = halfGap
            bottomDistance = halfGap
            topInset = 0
            bottomInset = 0
            topConstraint.constant = topDistance
            bottomConstraint.constant = bottomDistance
        } else {
            topInset = topDistance
            bottomInset = bottomDistance
        }
        
        scroll.contentInset = UIEdgeInsets(top: -topInset, left: 0, bottom: -bottomInset, right: 0)
    }
    
    func editStateChanged(state: EditState) {
        editState = state
        if case .inactive = state {
            scroll.isScrollEnabled = true
            panGesture.isEnabled = false
        } else {
            scroll.isScrollEnabled = false
            panGesture.isEnabled = true
        }
        
        if case .editing(let direction, _) = state, ["left", "right"].contains(direction) {
            containerWrapperCenterXConstraint.isActive = false
            containerWrapperLeadingConstraint.constant = containerWrapper.frame.minX
            containerWrapperTrailingConstraint.constant = scroll.frame.width - containerWrapper.frame.maxX
        } else if case .inactive(let fromDirections) = state {
            if let fromDirections = fromDirections {
                if ["left", "right"].contains(fromDirections) {
                    self.containerWrapperLeadingConstraint.constant = 0
                    self.containerWrapperTrailingConstraint.constant = 0
                    UIViewPropertyAnimator(duration: 0.15, curve: .linear, animations: {
                        self.containerWrapperCenterXConstraint.isActive = true
                        self.scroll.layoutIfNeeded()
                    }).startAnimation()
                } else {
                    UIView.animate(withDuration: 0.15, animations: {
                        self.resetGapToContainer()
                        self.containerWrapper.layoutIfNeeded()
                    })
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "preview":
             container.showSeperators(show: false)
             let previewController: PreviewController = segue.destination as! PreviewController
             previewController.uiImages = container.cells.map({ (cell) -> UIImage in
                return cell.exportSnapshot(wrapperBounds: cell.convert(containerWrapper.bounds, from: containerWrapper))
             })
             
             var cellFrames = [CGRect]()
             var height = CGFloat(0)
             for img in previewController.uiImages! {
                cellFrames.append(CGRect(origin: CGPoint(x: 0, y: height), size: img.size))
                height = height + img.size.height
             }
             previewController.cellFrames = cellFrames
             
             previewController.imageEntities = loadedImages
             container.showSeperators(show: true)
        default:
            break
        }
    }
}

// MARK: - Toolbar
extension ComposeController {
    
    func hightlightSlideItem(index: Int) {
        for (i, item) in slideTypeItems.enumerated() {
            let highlight = index == i
            if highlight {
                item.tintColor = UIColor.system
            } else {
                item.tintColor = UIColor.lightGray
            }
        }
    }
    
    @IBAction func onSlideItemSelected(_ sender: UIBarButtonItem) {
        hightlightSlideItem(index: 0)
        container.sliderType = .slide
        container.updateSliderType()
        container.setEditStateInvalid()
        container.showSeperators(show: true)
    }
    
    @IBAction func onCropItemSelected(_ sender: Any) {
        hightlightSlideItem(index: 1)
        container.sliderType = .crop
        container.updateSliderType()
        container.setEditStateInvalid()
        container.showSeperators(show: true)
    }
}

// MARK: - Zoom operation
extension ComposeController {
    
    func scaleContainerWrapper(scale: CGFloat) {
        containerWidthConstraint  = containerWidthConstraint.setMultiplier(multiplier: containerWidthConstraint.multiplier * scale)
        container.cells.forEach {$0.multiplyScale(scale: scale)}
        containerLeadingConstraint.constant = containerLeadingConstraintConstant.multiplyScale(scale)
        containerTrailingConstraint.constant = containerTrailingConstraintConstant.multiplyScale(scale)
    }
    
    fileprivate func updateAfterWrapperResize() {
        updateSideSliderButtons()
        updateSeperatorSliderButtons()
    }
    
    @IBAction func onPinchComposeView(_ gestureRecognizer: UIPinchGestureRecognizer) {
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            let maxScale = maxContainerWidth/containerWrapper.frame.width
            let scale = min(gestureRecognizer.scale, maxScale)
            
            let targetScale = containerWidthConstraint.multiplier * scale
            guard targetScale > 0.2 else {
                return
            }
            
            scaleContainerWrapper(scale: scale)
            
            if scale != 1 {
                lastScale = scale
            }
            gestureRecognizer.scale = 1.0
            
            updateAfterWrapperResize()
        } else if gestureRecognizer.state == .ended {
            
            let minScale = CGFloat(0.5)
            UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
                if self.containerWidthConstraint.multiplier < minScale {
                    self.scaleContainerWrapper(scale: minScale/self.containerWidthConstraint.multiplier)
                }
                
                self.resetGapToContainer()
                self.scroll.layoutIfNeeded()
                self.updateAfterWrapperResize()
            }.startAnimation()
        }
    }
}


extension ComposeController: UIScrollViewDelegate {
    
    fileprivate func updateSeperatorSliderButtons() {
        let midX = (min(container.frame.maxX, containerWrapper.bounds.maxX) - max(container.frame.minX, containerWrapper.bounds.minX)) / 2
        if let firstSeperator = container.seperators.first {
            let midPoint = firstSeperator.convert(CGPoint(x: midX, y: 0.0), from: containerWrapper)
            container.updateSeperatorSliderButtons(midPoint: midPoint)
        }
    }
    
    fileprivate func updateSideSliderButtons() {
        if container.leftSlider != nil {
            let fillScrollHeight = containerWrapper.bounds.height >= scroll.bounds.height
            let scrollMidPoint = containerWrapper.convert(CGPoint(x: 0, y: scroll.bounds.midY), from: scroll)
            let midPoint = container.leftSlider.convert(CGPoint(x: 0, y: fillScrollHeight ? scrollMidPoint.y : containerWrapper.bounds.midY), from: containerWrapper)
            container.leftSlider.updateSlider(midPoint: midPoint)
            container.rightSlider.updateSlider(midPoint: midPoint)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateSideSliderButtons()
    }
}
