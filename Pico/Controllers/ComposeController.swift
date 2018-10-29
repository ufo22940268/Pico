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
    @IBOutlet weak var scroll: ZoomScrollView!
    @IBOutlet weak var containerWrapper: UIView!
    
    @IBOutlet weak var wrapperWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var centerXOfContainerConstraint: NSLayoutConstraint!
    
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
            print("frameResult: \(frameResult)")
            
            let dispatchGroup = DispatchGroup()
            for index in 0..<images.count - 1 {
                dispatchGroup.enter()
                self.resolveImages(images: Array(images[index...index+1]), { (uiImages) in
                    let upImage = uiImages[0]
                    let downImage = uiImages[1]
                    OverlapDetector(upImage: upImage, downImage: downImage, frameResult: frameResult).detect {upOverlap, downOverlap in
                        DispatchQueue.main.async {
                            if upOverlap >= 0 && downOverlap >= 0 {
                                let hasError = upOverlap == 0 && downOverlap == 0
                                let imageHeight = uiImages[0].size.height
                                let upImageScrollDown: (CGFloat) = (!hasError ? upOverlap + frameResult.topGap : 0)
                                let downImageScrollUp: (CGFloat) = (!hasError ? downOverlap + frameResult.bottomGap : 0)
                                
                                print("imageScroll: \(upImageScrollDown) \(downImageScrollUp)")
                                self.container.cells[index].scrollDown(percentage: upImageScrollDown/imageHeight)
                                self.container.cells[index + 1].scrollUp(percentage: -downImageScrollUp/imageHeight)
                            }
                            dispatchGroup.leave()
                        }
                    }
                    
                    dispatchGroup.notify(queue: .main) {
                        self.hideLoading()
                        self.centerContainerWrapper()
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
        self.container.addTopSeperator(toView: self.view)
        self.container.addImage(imageEntity: images.first!)
//
        for image in images[1..<images.count] {
            self.container.addMiddleSeperator(toView: self.view)
            self.container.addImage(imageEntity: image)
        }
        
        self.container.addBottomSeperator(toView: self.view)
        
        self.container.addLeftSeperator(toView: self.view)
        self.container.addRightSeperator(toView: self.view)
        
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
        default:
            self.navigationItem.title = "竖向拼接"
            hideLoading()
            activeSlideMode()
        }
        
        scroll.layoutIfNeeded()
        updateSideSliderButtons()
        updateSeperatorSliderButtons()
        container.updateSliderType()
        
        updateContainerImages()
        setupScrollView()
        centerContainerWrapper()
    }
    
    func isDev() -> Bool {
        return loadUIImageHandler == nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isDev() {
            loadUIImageHandler = {
                self.type = .normal
                
//                //Photo library
//                let library = ImagesLibrary()
//                library.reload {
//                    let album = Album.selectAllPhotoAlbum(albums: library.albums)!
//                    let images = Array(album.items[0..<min(album.items.count, 2)])
//                    self.loadedImages = images
//
//                    self.configureImages(images)
//                }

                //Mocker
                let images = [ImageMocker(image: UIImage(named: "IMG_3975")!), ImageMocker(image: UIImage(named: "IMG_3976")!)]
                self.configureImages(images)
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
    }
    
    func setupScrollView() {
        scroll.delegate = self
        scroll.zoomDelegate = self
        syncSeperatorFrames()
    }
    
    func syncSeperatorFrames() {
        container.seperators.forEach {$0.syncFrame()}
        container.leftSlider.syncFrame()
        container.rightSlider.syncFrame()
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
            updateContainerImages()
        } else if sender.state == .ended {
            container.showSeperators(show: true)
        }
        
        scroll.layoutIfNeeded()
        updateSliders()
    }
    
    fileprivate func onScrollHorizontal(_ sender: UIPanGestureRecognizer, _ direction: String) {
        if sender.state == .changed {
            guard case .editing = editState else {
                return
            }
            
            let translate = sender.translation(in: container)
            var translateX = translate.x
            
            guard translateX != 0 else {
                return
            }
            
            let shrink = (translateX > 0 && direction == "right") || (translateX < 0 && direction == "left")
            
            if !horizontalScrollOverEdge(onDirection: direction, shrink: shrink, &translateX) {
                let newCenterX = centerXOfContainerConstraint.constant + translateX/2
                if shrink {
                    wrapperWidthConstraint.constant = wrapperWidthConstraint.constant - abs(translateX)
                } else {
                    wrapperWidthConstraint.constant = wrapperWidthConstraint.constant + abs(translateX)
                }

                centerXOfContainerConstraint.constant = newCenterX
                keepHorizontalPosition(inDirection: direction, translate: translateX)
            }
            
            sender.setTranslation(CGPoint.zero, in: container)
        }
        scroll.layoutIfNeeded()
        updateSliders()
    }
    
    var containerRectAfterCroppedByWrapper: CGRect {
        return container.convert(containerWrapper.bounds.intersection(container.frame), from: containerWrapper)
    }
    
    var visibleContainerRect: CGRect {
        let scrollRect = container.convert(scroll.bounds, from: scroll)
        return scrollRect.intersection(container.bounds)
    }
    
    let minimunGapBetweenSlides: CGFloat = 80
    
    func horizontalScrollOverEdge(onDirection direction: String, shrink: Bool, _ translateX: inout CGFloat) -> Bool {
        let validAreaWidth = containerRectAfterCroppedByWrapper.width
        let finalWidth = containerRectAfterCroppedByWrapper.width + (shrink ? -1 : 1)*abs(translateX)
        var maxWidth: CGFloat
        if direction == "left" {
            maxWidth = containerRectAfterCroppedByWrapper.maxX
        } else {
            maxWidth = scroll.bounds.width - containerRectAfterCroppedByWrapper.minX
        }
        
        if (validAreaWidth >= maxWidth && !shrink) || (validAreaWidth <= minimunGapBetweenSlides && shrink) {
            return true
        } else {
            if finalWidth > maxWidth {
                let absTranlsateX = (maxWidth - validAreaWidth) - (shrink ? -1 : 1)
                translateX = (translateX/abs(translateX))*absTranlsateX
            } else if finalWidth < minimunGapBetweenSlides {
                let absTranlsateX = (minimunGapBetweenSlides - validAreaWidth) - (shrink ? -1 : 1)
                translateX = (translateX/abs(translateX))*absTranlsateX
            }
            return false
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
            updateSliders()
            return
        }
        
        if case .editing(let direction, _) = editState {
            if editState.maybeVertical() {
                onScrollVertical(sender)
            } else {
                onScrollHorizontal(sender, direction)
            }
        }
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
            
        } else if case .inactive = state {
            UIView.animate(withDuration: 0.15, animations: {
                self.syncSeperatorFrames()
                self.centerContainerWrapper()
            })
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
                item.tintColor = UIColor.gray
            }
        }
    }
    
    func dimAllSlideItems() {
        hightlightSlideItem(index: -1)
    }
    
    func resetEditState() {
        container.resetEditState()
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

extension ComposeController: UIScrollViewDelegate {
    
    fileprivate var sliderButtonTransform: CGAffineTransform {
        let transform = containerWrapper.transform.inverted()
        return CGAffineTransform(scaleX: transform.a, y: transform.a)
    }
    
    fileprivate func updateSeperatorSliderButtons() {
        if let firstSeperator = container.seperators.first {
            let midPoint = CGPoint(x: firstSeperator.convert(visibleContainerRect, from: container).midX, y: 0)
            container.updateSeperatorSliders(midPoint: midPoint)
        }
    }
    
    fileprivate func updateSideSliderButtons() {
        if container.leftSlider != nil {
            let fillScrollHeight = containerWrapper.bounds.height >= scroll.bounds.height
            let scrollMidPoint = containerWrapper.convert(CGPoint(x: 0, y: scroll.bounds.midY), from: scroll)
            let midPoint = container.leftSlider.convert(CGPoint(x: 0, y: fillScrollHeight ? scrollMidPoint.y : containerWrapper.bounds.midY), from: containerWrapper)
            container.leftSlider.update(midPoint: midPoint)
            container.rightSlider.update(midPoint: midPoint)
        }
    }
    
    fileprivate func updateSliders() {
        updateSeperatorSliderButtons()
        updateSideSliderButtons()
        syncSeperatorFrames()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateSideSliderButtons()
        updateSeperatorSliderButtons()
        updateContainerImages()
        syncSeperatorFrames()
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerWrapper
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateSeperatorSliderButtons()
        centerContainerWrapper()
//        updateSideSliderButtons()
    }
    
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        centerContainerWrapper()
//        updateSideSliderButtons()
//        updateSeperatorSliderButtons()
    }
    
    
    
    
    fileprivate func centerContainerWrapper() {
        let scrollBounds = scroll.bounds
        let offsetX = max((scrollBounds.width - scroll.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollBounds.height - scroll.contentSize.height) * 0.5, 0)
        scroll.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }
    
    override func viewDidLayoutSubviews() {
        switch editState {
        case .inactive:
            centerContainerWrapper()
        default:
            break
        }
    }
}

extension ComposeController: ZoomScrollViewDelegate {
    func onChangeTo(scale: CGFloat) {
        let midX = (min(container.frame.maxX, containerWrapper.bounds.maxX) - max(container.frame.minX, containerWrapper.bounds.minX)) / 2
        if let firstSeperator = container.seperators.first {
            let midPoint = firstSeperator.convert(CGPoint(x: midX, y: 0.0), from: containerWrapper)
//            container.updateSeperatorSliders(midPoint: midPoint)
        }
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

