//
//  ComposeController.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/3.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit

class ComposeController: UIViewController, EditDelegator, OnCellScroll {
    
    @IBOutlet weak var container: ComposeContainerView!
    @IBOutlet weak var scroll: UIScrollView!
    @IBOutlet weak var containerWrapper: UIView!
    
    @IBOutlet var topConstraint: NSLayoutConstraint!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    
    let minContainerWidth = CGFloat(230)
    let maxContainerWidth = UIScreen.main.bounds.width
    var lastScale = CGFloat(1.0)
    
    
    var editState: ComposeContainerView.EditState = ComposeContainerView.EditState.inactive
    
    var panView: ComposeCell!
    
    var loadedImages:[Image]!
    
    @IBOutlet weak var containerWrapperWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet var panGesture: UIPanGestureRecognizer!
    
    enum ConcatenateType {
        case screenshot
        case normal
        case movie
    }
    
    var type: ConcatenateType!
    
    fileprivate func concateScreenshot(_ uiImages: ([UIImage?])) {
        OverlapDetector(upImage: uiImages[0]!, downImage: uiImages[1]!).detect {upOverlap, downOverlap in
            DispatchQueue.main.async {
                if upOverlap > 0 && downOverlap > 0 {
                    for i in 0..<uiImages.count - 1 {
                        let imageHeight = uiImages[0]!.size.height
                        self.container.cells[i].scrollDown(percentage: upOverlap/imageHeight)
                        self.container.cells[i + 1].scrollUp(percentage: -downOverlap/imageHeight)
                    }
                }
                self.resetGapToContainer()
            }
        }
    }
    
    fileprivate func configureUIImages(_ uiImages: ([UIImage?])) {
        self.container.addTopSeperator()
        
        self.container.addImage(image: uiImages.first!!)
        
        uiImages[1..<uiImages.count].forEach { image in
            self.container.addSeperator()
            self.container.addImage(image: image!)
        }
        
        self.container.addBottomSeperator()
        
        self.container.subviews.filter{$0.isKind(of: SeperatorSlider.self)}.forEach {self.container.bringSubview(toFront: $0)}
        
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if loadedImages == nil {
            self.configureUIImages([UIImage(named: "short"), UIImage(named: "short2")])
        } else if loadedImages.count >= 2 {
            Image.resolve(images: loadedImages, completion: {uiImages in
                self.configureUIImages(uiImages)
            })
        }
        
        container.setEditDelegator(delegator: self)
        container.scrollDelegator = self
    }
    
    @IBAction func download(_ sender: UIBarButtonItem) {
        container.showSeperators(show: false)
        let image = container.exportImageCache()
        let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(vc, animated: true, completion: {self.container.showSeperators(show: true)})
    }
    
    @IBAction func onScroll(_ sender: UIPanGestureRecognizer) {
        
        guard case .editing = editState else {
            return
        }
        
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
            panView.onScroll(sender)
            container.showSeperators(show: false)
        } else if sender.state == .ended {
            container.showSeperators(show: true)
        }
    }
    
    func findScrollCell(hitView: UIView) -> ComposeCell? {
        let cellIndex = container.cells.enumerated().filter {$0.element == hitView}.first!.offset
        if case .editing(let seperatorIndex) = editState {
            if cellIndex < seperatorIndex {
                return container.cells[seperatorIndex - 1]
            } else {
                return container.cells[seperatorIndex]
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
        
        if container.frame.height < scroll.frame.height {
            let halfGap = (scroll.frame.height - container.frame.height)/2
            topDistance = topDistance - halfGap
            bottomDistance = bottomDistance - halfGap
        }
        
        scroll.contentInset = UIEdgeInsets(top: -topDistance, left: 0, bottom: -bottomDistance, right: 0)
    }
    
    func editStateChanged(state: ComposeContainerView.EditState) {
        editState = state
        if case .inactive = state {
            scroll.isScrollEnabled = true
            panGesture.isEnabled = false
        } else {
            scroll.isScrollEnabled = false
            panGesture.isEnabled = true
        }
        
        if case .inactive = state {
            self.containerWrapper.layoutIfNeeded()
            UIView.animate(withDuration: 0.14, animations: {
                self.resetGapToContainer()
                self.containerWrapper.layoutIfNeeded()
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
             let cellFrames = container.cells.map{$0.frame}
             let previewController: PreviewController = segue.destination as! PreviewController
             previewController.uiImages = [container.exportImageCache()!]
             previewController.cellFrames = cellFrames
             container.showSeperators(show: true)
        default:
            break
        }
    }
}

// MARK: - Zoom operation
extension ComposeController {
    
    func scaleContainerWrapper(scale: CGFloat) {
        containerWrapperWidthConstraint  = containerWrapperWidthConstraint.setMultiplier(multiplier: containerWrapperWidthConstraint.multiplier * scale)
    }
    
    @IBAction func onToggleZoom(_ sender: UITapGestureRecognizer) {
        if container.frame.width == minContainerWidth {
            scaleContainerToWidthWithAnimation(width: maxContainerWidth)
        } else {
            scaleContainerToWidthWithAnimation(width: minContainerWidth)
        }
    }

    
    @IBAction func onPinchComposeView(_ gestureRecognizer: UIPinchGestureRecognizer) {
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            let maxScale = maxContainerWidth/containerWrapper.frame.width
            let scale = min(gestureRecognizer.scale, maxScale)
            scaleContainerWrapper(scale: scale)

            if scale != 1 {
                lastScale = scale
            }
            gestureRecognizer.scale = 1.0
        } else if gestureRecognizer.state == .ended {

            resetGapToContainer()
            if containerWrapper.frame.width < minContainerWidth {
                scaleContainerToWidthWithAnimation(width: minContainerWidth)
                gestureRecognizer.scale = 1.0
            } else if lastScale < 1 {
                scaleContainerToWidthWithAnimation(width: minContainerWidth)
                gestureRecognizer.scale = 1.0
            } else if lastScale > 1 {
                scaleContainerToWidthWithAnimation(width: maxContainerWidth)
                gestureRecognizer.scale = 1.0
            }
        }
        
        containerWrapper.setNeedsLayout()
    }
    
    func scaleContainerToWidthWithAnimation(width: CGFloat) {
        UIViewPropertyAnimator(duration: 0.3, curve: .easeOut, animations: {
            let scale = width/self.containerWrapper.frame.width
            self.scaleContainerWrapper(scale: scale)
           }).startAnimation()
    }
}
