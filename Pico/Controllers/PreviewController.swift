//
//  PreviewController.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/16.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit
import GLKit

enum SelectRegionState {
    case start, end
}

enum PreviewMode {
    case none, pixellate, sign, frame
}

extension UIScrollView {
    func scrollToBottom() {
        contentOffset = CGPoint(x: 0, y: contentSize.height - bounds.height)
    }
}

struct SelectRegion {
    var startPoint: CGPoint!
    var endPoint: CGPoint!
    var state: SelectRegionState!
    
    
    func toRect() -> CGRect? {
        guard  startPoint != nil && endPoint != nil else {
            return nil
        }
        let centerPoint = CGPoint(x: (startPoint.x + endPoint.x)/2, y: (startPoint.y + endPoint.y)/2)
        let xl = abs(centerPoint.x - startPoint.x)
        let yl = abs(centerPoint.y - startPoint.y)
        let topLeftPoint = CGPoint(x: centerPoint.x - xl, y: centerPoint.y - yl)
        return CGRect(origin: topLeftPoint, size: CGSize(width: xl*2, height: yl*2))
    }
}

enum PreviewAlignMode: Int {
    case left = 0
    case middle = 1
    case right = 2
}

enum PreviewFrameType {
    case none, full, seperator
}

class PreviewController: UIViewController {
    
    @IBOutlet weak var preview: PreviewView!
    @IBOutlet weak var scroll: UIScrollView!
    var selectRegion: SelectRegion!
    
    @IBOutlet weak var pixellateToolbar: UIToolbar!
    @IBOutlet weak var signToolbar: UIToolbar!
    @IBOutlet weak var frameToolbar: UIToolbar!
    
    @IBOutlet weak var cover: PreviewCover!
    @IBOutlet var pixelllateGesture: UIPanGestureRecognizer!
    
    //Signature toolbar items
    @IBOutlet weak var signCancelItem: UIBarButtonItem!
    @IBOutlet weak var signAlignLeftItem: UIBarButtonItem!
    @IBOutlet weak var signAlignMiddleItem: UIBarButtonItem!
    @IBOutlet weak var signAlignRightItem: UIBarButtonItem!
    
    @IBOutlet var widthConstraint: NSLayoutConstraint!
    
    @IBOutlet var centerXConstraint: NSLayoutConstraint!
    @IBOutlet var centerYConstraint: NSLayoutConstraint!
    
    var cellFrames: [CGRect] = [CGRect]()
    var cropRects: [CGRect] = [CGRect]()
    
    let sampleImages: [UIImage] = [UIImage(named: "very_short")!, UIImage(named: "short")!]
    var uiImages: [UIImage]?
    var imageEntities: [Image]!
        
    let minScale = CGFloat(0.5)
    let maxScale = CGFloat(2.0)
    let toolbarHeight = CGFloat(44)
    
    @IBOutlet var pixelItems: [UIBarButtonItem]!
    
    @IBOutlet var tabToolbarItems: [UIBarButtonItem]!
    var subToolbarOpen : Bool = false
    
    var bottomToolbarHeight : CGFloat {
        if subToolbarOpen {
            return 44
        } else {
            return 0
        }
    }
    
    var isDev: Bool = true
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    var mode:PreviewMode = .none {
        willSet(mode) {
            switch mode {
            case .sign:
                onSubToolbarOpen(true)
                scrollToBottom()
                activeToolbarItem(at: 0)
                break
            case .frame:
                onSubToolbarOpen(true)
                scrollToBottomIfNeeded()
                activeToolbarItem(at: 1)
                break
            case .pixellate:
                cover.isUserInteractionEnabled = true
                self.pixelllateGesture.isEnabled = true
                onSubToolbarOpen(true)
                scrollToBottomIfNeeded()
                activeToolbarItem(at: 2)
                break
            case .none:
                cover.isUserInteractionEnabled = false
                self.pixelllateGesture.isEnabled = false
                hideToolbarItems()
                onSubToolbarOpen(false)
                activeToolbarItem(at: nil)
            }
        }
    }
    
    func activeToolbarItem(at position: Int?) {
        tabToolbarItems.enumerated().forEach {offset, item in
            if offset == position {
                item.tintColor = UIColor.system
            } else {
                item.tintColor = UIColor.gray
            }
        }
    }
    
    func scrollToBottomIfNeeded() {
        if scroll.contentSize.height - (scroll.contentOffset.y + scroll.bounds.height) < toolbarHeight {
            scrollToBottom()
        }
    }
    
    func scrollToBottom() {
        guard scroll.contentSize.height > scroll.bounds.height else {
            return
        }
        scroll.setContentOffset(CGPoint(x: scroll.contentOffset.x, y: scroll.contentSize.height - scroll.bounds.height + bottomToolbarHeight), animated: true)
    }
    
    func forDev() -> Bool {
        return isDev
    }
    
    var initializeClosure: (() -> Void)?
    
    func setupAfterLoaded() {
        preview.uiImages = uiImages
        preview.setupCells(images: imageEntities, crops: cropRects)
        
        preview.sign = nil
        
        scroll.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomToolbarHeight, right: 0)
        
        updatePixelSelection(tag: 0)
        
        scroll.maximumZoomScale = 2.0
        scroll.minimumZoomScale = 0.5
        scroll.delegate = self
        
        onSignChanged(sign: nil)
        hideLoading()
        
        scroll.layoutIfNeeded()
        preview.loadImages(scrollView: scroll)
        activeToolbarItem(at: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if forDev() {
            initializeClosure = {
                let library = ImagesLibrary()
                library.reload {
                    let album = Album.selectAllPhotoAlbum(albums: library.albums)!
                    self.imageEntities = Array(album.items[0..<min(album.items.count, 2)])
                    self.cropRects = (0..<self.imageEntities.count).map {_ in CGRect(origin: CGPoint.zero, size: CGSize(width: 1, height: 1))}
                    self.preview.imageEntities = self.imageEntities
                    self.setupAfterLoaded()
                }
            }
        }

        if let initializeClosure = initializeClosure {
            showLoading()
            initializeClosure()
        }
        initializeClosure = nil
    }
    
    func showLoading() {
        loadingIndicator.startAnimating()
        scroll.isHidden = true
    }
    
    func hideLoading() {
        loadingIndicator.stopAnimating()
        scroll.isHidden = false
    }

    override func viewDidLayoutSubviews() {
        centerPreview()
    }    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func insidePreview(selection: CGRect) -> Bool {
        let contains = preview.bounds.contains(selection.applying(CGAffineTransform(scaleX: preview.bounds.width, y: preview.bounds.height)))
        return contains
    }
    
    @IBAction func onSelectRegion(_ sender: UIPanGestureRecognizer) {
        let currentPoint = sender.location(in: preview).applying(CGAffineTransform(scaleX: 1/preview.bounds.width, y: 1/preview.bounds.height))
        if sender.state == .began {
            selectRegion = SelectRegion()
            selectRegion.state = .start
            selectRegion.startPoint = currentPoint
        } else if sender.state == .changed {
            selectRegion.state = .end
            selectRegion.endPoint = currentPoint
            if let selection = selectRegion.toRect(), insidePreview(selection: selection) {
                cover.drawSelection(rect: cover.convert(selection.applying(CGAffineTransform(scaleX: preview.bounds.width, y: preview.bounds.height)), from: preview) )
                preview.updatePixellate(uiRect: selection)
            }
        } else if sender.state == .ended {
            cover.clearSelection()
            preview.closeLastRectCrop()
        }
        
        preview.setNeedsDisplay()

    }
    
    @IBAction func onUndo(_ sender: Any) {
        preview.undo()
        preview.setNeedsDisplay()
    }
    
    func hideToolbarItems() {
        let allToolbars = [pixellateToolbar, signToolbar, frameToolbar]
        allToolbars.forEach {$0?.isHidden = true}
    }

    
    func updatePixelSelection(tag: Int) {
        pixelItems.forEach { item in
            if item.tag == tag {
                item.tintColor = view.tintColor
            } else {
                item.tintColor = UIColor.lightGray
            }
        }
    }
}

extension PreviewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return preview
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
    }
    
    fileprivate func centerPreview() {
        let offsetX = max((scroll.bounds.width - scroll.contentSize.width) * 0.5, 0)
        let offsetY = max((scroll.bounds.height - scroll.contentSize.height) * 0.5, 0)
        scroll.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: bottomToolbarHeight, right: 0)
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerPreview()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        preview.loadImages(scrollView: scrollView)
    }
}

// MARK: - Frame feature
extension PreviewController {
    
    @IBAction func onFrameItemClick(_ sender: UIBarButtonItem) {
        if mode == .frame {
            mode = .none
        } else {
            showToolbarItem(frameToolbar)
            mode = .frame
        }
    }
    
    @IBAction func onFrameCancelClick(_ sender: UIBarButtonItem) {
        preview.updateFrame(.none)
    }
    
    @IBAction func onFrameSeperatorModeClick(_ sender: Any) {
        preview.updateFrame(.seperator)
    }
    
    @IBAction func onFrameFullModeClick(_ sender: Any) {
        preview.updateFrame(.full)
    }
}

// MARK: - Toolbar
extension PreviewController {
    
    func showToolbarItem(_ item: UIToolbar) {
        hideToolbarItems()
        item.isHidden = false
    }
    
    @IBAction func onShareClick(_ sender: Any) {
        let shareManager: ShareManager = ShareManager(viewController: self)
        shareManager.showActions()
    }
    
    @IBAction func onPixellateItemClick(_ sender: Any) {
        if mode == .pixellate {
            mode = .none
        } else {
            showToolbarItem(pixellateToolbar)
            mode = .pixellate
        }
    }
    
    @IBAction func onSignItemClick(_ sender: Any) {
        if mode == .sign {
            mode = .none
        } else {
            showToolbarItem(signToolbar)
            mode = .sign
        }
    }
    
    @IBAction func onPixelItemClick(_ sender: UIBarButtonItem) {
        let tagToScale = [
            0: PreviewPixellateScale.small,
            1: .middle,
            2: .large
        ]
                
        preview.setPixelScale(scale: tagToScale[sender.tag]!)
        preview.updatePixelInCells()
        preview.setNeedsDisplay()
        
        updatePixelSelection(tag: sender.tag)
    }

    func onSignChanged(sign: String?) {
        let showItems = sign != nil
        signCancelItem.isEnabled = showItems
        signAlignLeftItem.isEnabled = showItems
        signAlignMiddleItem.isEnabled = showItems
        signAlignRightItem.isEnabled = showItems
        preview.reloadVisibleCells()
    }
    
    @IBAction func onEditSign(_ sender: Any) {
        let alert = UIAlertController(title: "签名编辑", message: "请输入你的签名", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
            if let sign = alert.textFields!.first!.text  {
                self.preview.setSign(sign: sign)
                self.onSignChanged(sign: sign)
                self.preview.setNeedsDisplay()
            }
        }))
        
        alert.addTextField { (textField) in
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func onAlignClick(_ sender: UIBarButtonItem) {
        preview.setAlign(align: PreviewAlignMode(rawValue: sender.tag)!)
        self.preview.reloadVisibleCells()
    }
    
    @IBAction func clearSign(_ sender: Any) {
        let alert  = UIAlertController(title: nil, message: "确定重置签名吗", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (_) in
            self.preview.clearSign()
            self.onSignChanged(sign: nil)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func onSubToolbarOpen(_ open: Bool) {
        subToolbarOpen = open
        centerPreview()
    }
}


extension PreviewController : ShareImageGenerator {
    func generateImage(callback: @escaping (UIImage) -> Void) {
        preview.renderImageForExport(imageEntities: imageEntities, cropRects: cropRects, complete: { image in
            DispatchQueue.main.async {
                callback(image)
            }
        })
    }
}
