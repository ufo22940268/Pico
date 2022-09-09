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
    
    @IBOutlet var pixelItems: [UIBarButtonItem]!
    let bottomToolbarHeight = CGFloat(44)
    
    var mode:PreviewMode = .none {
        willSet(mode) {
            switch mode {
            case .pixellate:
                cover.isUserInteractionEnabled = true
                self.pixelllateGesture.isEnabled = true
            case .sign:
                scroll.setContentOffset(CGPoint(x: 0.0, y: scroll.contentSize.height - scroll.frame.height + bottomToolbarHeight), animated: true)
                break
            case .frame:
                break
            case .none:
                cover.isUserInteractionEnabled = false
                self.pixelllateGesture.isEnabled = false
                hideToolbarItems()
            }
        }
    }
    
    func forDev() -> Bool {
        return uiImages == nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if forDev() {
            uiImages = Array(0..<2).map {sampleImages[$0%2]}
            imageEntities = sampleImages.map {ImageMocker(image: $0)}
            var height = CGFloat(0)
            for uiImage in uiImages! {
                cellFrames.append(CGRect(origin: CGPoint(x: 0, y: height), size: uiImage.size))
                cropRects.append(CGRect(origin: CGPoint.zero, size: CGSize(width: 1, height: 1)))
                height = height + uiImage.size.height
            }            
        }
        
        preview.uiImages = uiImages
        preview.image = preview.setupCells(images: (uiImages!.map({ (uiImage) -> CIImage in
            return CIImage(image: uiImage)!
        })))

        let previewImageSize = preview.image.extent
        let ratio: CGFloat = previewImageSize.width/previewImageSize.height
        
        let imageViewHeight = scroll.frame.size.width/ratio
        scroll.centerImage(imageViewHeight: imageViewHeight)
        
        preview.heightAnchor.constraint(equalToConstant: imageViewHeight)
        preview.sign = nil
        
        scroll.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomToolbarHeight, right: 0)
        
        updatePixelSelection(tag: 0)
        
        scroll.maximumZoomScale = 2.0
        scroll.minimumZoomScale = 0.5
        scroll.delegate = self

        onSignChanged(sign: nil)
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
                let imageRect = selection.applying(preview.transform)
                preview.updatePixellate(uiRect: imageRect)
            }

        } else if sender.state == .ended {
            cover.clearSelection()

            if let selection = selectRegion.toRect(), insidePreview(selection: selection) {
                let imageRect = selection.applying(preview.transform)
                preview.addPixellate(uiRect: imageRect)
            }
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
        preview.refreshPixelImage()
        preview.setNeedsDisplay()
        
        updatePixelSelection(tag: sender.tag)
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
        scroll.contentInset = UIEdgeInsetsMake(offsetY, offsetX, bottomToolbarHeight, 0)
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerPreview()
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

// MARK: - Sign
extension PreviewController {
    
    func onSignChanged(sign: String?) {
        let showItems = sign != nil
        signCancelItem.isEnabled = showItems
        signAlignLeftItem.isEnabled = showItems
        signAlignMiddleItem.isEnabled = showItems
        signAlignRightItem.isEnabled = showItems
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
    }
    
    @IBAction func clearSign(_ sender: Any) {
        self.preview.clearSign()
        onSignChanged(sign: nil)
    }
}


extension PreviewController : ShareImageGenerator {
    func generateImage(callback: @escaping (UIImage) -> Void) {
        preview.renderImageForExport(imageEntities: imageEntities, cropRects: cropRects, complete: { image in
            callback(image)
        })
    }
}
