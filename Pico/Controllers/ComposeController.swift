//
//  ComposeController.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/3.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit
import Photos

enum SliderType {
    case crop, slide, none
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
    
    var loadedImages:[Image]!
    
    var loadUIImageHandler:(() -> Void)?
    
    @IBOutlet weak var containerWidthConstraint: NSLayoutConstraint!
    @IBOutlet var panGesture: UIPanGestureRecognizer!
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    enum ConcatenateType {
        case screenshot
        case normal
        case movie
    }
    
    var type: ConcatenateType!


    func resolveImages(images: [Image], _ completion: @escaping ([UIImage]) -> Void) {
        Image.resolve(images: images, resizeMode: .none) { (images) in
            completion(images.map {$0!})
        }
    }
    
    func detectFrame(images: [Image], _ complete: @escaping (FrameDetectResult) -> Void) {
        resolveImages(images: images) { (uiImages) in
            let frameResult = FrameDetector(upImage: uiImages.first!, downImage: uiImages[1]).detect()
            complete(frameResult)
        }
    }

    fileprivate func concateScreenshot(_ images: ([Image])) {
        detectFrame(images: Array(images[0..<2])) { (frameResult) in
            let dispatchGroup = DispatchGroup()
            for index in 0..<images.count - 1 {
                dispatchGroup.enter()
                self.resolveImages(images: Array(images[index...index+1]), { (uiImages) in
                    let upImage = uiImages[0]
                    let downImage = uiImages[1]
                    OverlapDetector(upImage: upImage, downImage: downImage, frameResult: frameResult).detect {upOverlap, downOverlap in
                        DispatchQueue.main.async {
                            if upOverlap > 0 && downOverlap > 0 {
                                let imageHeight = uiImages[0].size.height
                                print(index, "up", upOverlap, "down", downOverlap)
                                self.container.cells[index].scrollDown(percentage: upOverlap/imageHeight)
                                self.container.cells[index + 1].scrollUp(percentage: -downOverlap/imageHeight)
                            }
                            dispatchGroup.leave()
                        }
                    }
                    
                    dispatchGroup.notify(queue: .main) {
                        self.hideLoading()
                        self.resetGapToContainer()
                    }
                })
            }
        }
    }
    
    func configureImages(_ images: ([Image])) {
        guard images.count >= 2 else {
            return
        }
        
        self.loadedImages = images
        self.container.addTopSeperator()
        self.container.addImage(imageEntity: images.first!)
//
        for image in images[1..<images.count] {
            self.container.addSeperator()
            self.container.addImage(imageEntity: image)
        }
        
        self.container.addBottomSeperator()
        
        self.container.addLeftSeperator()
        self.container.leftSlider.leadingAnchor.constraint(equalTo: containerWrapper.leadingAnchor).isActive = true
        self.container.addRightSeperator()
        self.container.rightSlider.trailingAnchor.constraint(equalTo: containerWrapper.trailingAnchor).isActive = true
        
        self.container.subviews.filter{$0.isKind(of: SeperatorSlider.self)}.forEach {self.container.bringSubviewToFront($0)}
        self.container.subviews.filter{$0.isKind(of: SideSlider.self)}.forEach {
            self.container.bringSubviewToFront($0)            
        }

        switch self.type! {
        case .screenshot:
            self.concateScreenshot(images)
            self.navigationItem.title = "长截图"
            activeCropMode()
            break
        case .movie:
//            MovieConcate(cells: self.container.cells, images: uiImages).scrollCells()
//            hideLoading()
//            self.navigationItem.title = "电影截图"
//            activeCropMode()
            break
        default:
            self.navigationItem.title = "竖向拼接"
            hideLoading()
            activeSlideMode()
        }
        
        scroll.layoutIfNeeded()
        self.resetGapToContainer()
        updateSideSliderButtons()
        container.updateSliderType()
        
        updateContainerImages()
    }
    
    func isDev() -> Bool {
        return loadUIImageHandler == nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isDev() {
            loadUIImageHandler = {
                self.type = .screenshot
                
                //Photo library
                let library = ImagesLibrary()
                library.reload {
                    let album = Album.selectAllPhotoAlbum(albums: library.albums)!
                    let images = Array(album.items[0..<min(album.items.count, 6)])
                    self.loadedImages = images

                    self.configureImages(images)
                }

                //Mocker
//                let images = [ImageMocker(image: UIImage(named: "IMG_0009")!), ImageMocker(image: UIImage(named: "IMG_0010")!)]
//                self.configureImages(images)
            }
        }
        
        showLoading()

        loadUIImageHandler?()
        
        // To solve compose controller memory issue, but i am not sure if it's a good solution.
        loadUIImageHandler = nil
        
        if type == .screenshot {
            container.sliderType = .crop
        } else {
            container.sliderType = .slide
        }
        
        toolbarItems?.first?.setBackgroundImage(UIImage(named: "crop-alt-solid-fade"), for: .highlighted, barMetrics: .default)
        
        container.setEditDelegator(delegator: self)
        container.scrollDelegator = self
        
        setupScrollView()
    }
    
    func setupScrollView() {
        scroll.delegate = self
        scroll.maximumZoomScale = 2
        scroll.minimumZoomScale = 0.4
    }
    
    func showLoading() {
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()

        scroll.isHidden = true
    }
    
    func hideLoading() {
        loadingIndicator.isHidden = true
        loadingIndicator.stopAnimating()
        scroll.isHidden = false
    }
    
    
    @IBAction func download(_ sender: UIBarButtonItem) {
        let shareManager: ShareManager = ShareManager(viewController: self)
        shareManager.showActions()
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
            container.showActiveSeperator()
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
            

            keepHorizontalPosition(inDirection: direction, translate: calibratedTranslateX)
            
            sender.setTranslation(CGPoint.zero, in: container)
        }
    }
    
    func keepHorizontalPosition(inDirection direction: String,  translate: CGFloat) {
        if direction == "left" {
            scroll.contentInset.right = scroll.contentInset.right - translate
        } else if direction == "right" {
            scroll.contentInset.left = scroll.contentInset.left + translate
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
    
    func updateContainerImages() {
        container.loadImages(scrollView: scroll)
    }
   
    func findScrollCell(hitView: UIView) -> ComposeCell? {
        let cellIndex = container.cells.enumerated().filter {$0.element == hitView}.first!.offset
        if case .editing( _, let seperatorIndex) = editState {
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
    
    fileprivate func keepVerticalPosition(_ position: ComposeCell.Position, _ distanceVector: CGFloat) {
        if case .above = position {
            var contentInset = scroll.contentInset
            contentInset.top = contentInset.top + distanceVector
            scroll.contentInset = contentInset
            
            var offset = scroll.contentOffset
            offset.y = offset.y - distanceVector
            scroll.contentOffset = offset
        } else if case .below = position {
            var contentInset = scroll.contentInset
            contentInset.bottom = contentInset.bottom - distanceVector
            scroll.contentInset = contentInset
        }
    }
    
    func onCellScroll(translate: Float, cellIndex: Int, position: ComposeCell.Position) {
        let scale = getContainerScale()
        let distanceVector = CGFloat(translate)*scale
        keepVerticalPosition(position, distanceVector)
    }

    fileprivate func resetGapToContainer() {
        topConstraint.constant = 0
        bottomConstraint.constant = 0
        centerContainerWrapper()
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
            
        } else if case .inactive(let fromDirections) = state {
            if let fromDirections = fromDirections {
                if ["left", "right"].contains(fromDirections) {
                    self.containerWrapperLeadingConstraint.constant = 0
                    self.containerWrapperTrailingConstraint.constant = 0
                    UIViewPropertyAnimator(duration: 0.15, curve: .linear, animations: {
                        self.resetGapToContainer()
                    }).startAnimation()
                } else {
                    UIView.animate(withDuration: 0.15, animations: {
                        self.resetGapToContainer()
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
             
             previewController.isDev = false
             
             previewController.initializeClosure = {() in
                previewController.cropRects = self.container.cells.map({ (cell) -> CGRect in
                    return cell.getIntersection(wrapperBounds: cell.convert(self.containerWrapper.bounds, from: self.containerWrapper))
                })
                
                previewController.imageEntities = self.loadedImages
                previewController.preview.imageEntities = self.loadedImages
                self.container.showSeperators(show: true)
                previewController.setupAfterLoaded()
             }
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
                item.tintColor = UIColor.black
            }
        }
    }
    
    func dimAllSlideItems() {
        hightlightSlideItem(index: -1)
    }
    
    fileprivate func activeSlideMode() {
        hightlightSlideItem(index: 0)
        container.sliderType = .slide
        container.updateSliderType()
        container.showSeperators(show: true)
    }
    
    fileprivate func selectNoneSlideMode() {
        container.sliderType = .none
        dimAllSlideItems()
        container.updateSliderType()
        container.showSeperators(show: false)
    }
    
    fileprivate func activeCropMode() {
        hightlightSlideItem(index: 1)
        container.sliderType = .crop
        container.updateSliderType()
        container.showSeperators(show: true)
    }
    
    @IBAction func onCropItemSelected(_ sender: Any) {
        if container.sliderType == .crop {
            selectNoneSlideMode()
        } else {
            activeCropMode()
        }
    }
    
    @IBAction func onSlideItemSelected(_ sender: UIBarButtonItem) {
        if container.sliderType == .slide {
            selectNoneSlideMode()
        } else {
            activeSlideMode()
        }
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
            guard targetScale > 0.5 else {
                return
            }
            
            scaleContainerWrapper(scale: scale)
            
            if scale != 1 {
                lastScale = scale
            }
            gestureRecognizer.scale = 1.0
            
            updateAfterWrapperResize()
            updateContainerImages()
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
            updateContainerImages()
        }
    }
}


extension ComposeController: UIScrollViewDelegate {
    
    fileprivate var sliderButtonTransform: CGAffineTransform {
        let transform = containerWrapper.transform.inverted()
        return CGAffineTransform(scaleX: transform.a, y: transform.a)
    }
    
    fileprivate func updateSeperatorSliderButtons() {
        let midX = (min(container.frame.maxX, containerWrapper.bounds.maxX) - max(container.frame.minX, containerWrapper.bounds.minX)) / 2
        if let firstSeperator = container.seperators.first {
            let midPoint = firstSeperator.convert(CGPoint(x: midX, y: 0.0), from: containerWrapper)
            container.updateSeperatorSliders(midPoint: midPoint, transform: sliderButtonTransform)
        }
    }
    
    
    fileprivate func updateSideSliderButtons() {
        if container.leftSlider != nil {
            let fillScrollHeight = containerWrapper.bounds.height >= scroll.bounds.height
            let scrollMidPoint = containerWrapper.convert(CGPoint(x: 0, y: scroll.bounds.midY), from: scroll)
            let midPoint = container.leftSlider.convert(CGPoint(x: 0, y: fillScrollHeight ? scrollMidPoint.y : containerWrapper.bounds.midY), from: containerWrapper)
            container.leftSlider.update(midPoint: midPoint)
            container.leftSlider.updateScale(sliderButtonTransform.a)
            container.rightSlider.update(midPoint: midPoint)
            container.rightSlider.updateScale(sliderButtonTransform.a)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateSideSliderButtons()
        updateContainerImages()
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerWrapper
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContainerWrapper()
        updateSideSliderButtons()
        updateSeperatorSliderButtons()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        centerContainerWrapper()
        updateSideSliderButtons()
        updateSeperatorSliderButtons()
    }
    
    fileprivate func centerContainerWrapper() {
        let scrollBounds = scroll.bounds
        let offsetX = max((scrollBounds.width - scroll.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollBounds.height - scroll.contentSize.height) * 0.5, 0)
        scroll.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }
}

extension ComposeController: ShareImageGenerator {
    func generateImage(callback: @escaping (UIImage) -> Void) {
        let rect: CGRect = self.container.convert(self.containerWrapper.bounds, from: self.containerWrapper)
        self.container.exportSnapshot(callback: {snapshot in
            DispatchQueue.main.async {
                callback(snapshot)
            }
        }, wrapperBounds: rect)
    }
}
