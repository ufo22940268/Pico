//
//  PreviewCell.swift
//  Pico
//
//  Created by Frank Cheng on 2018/9/3.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import GLKit

class PreviewCell: GLKView {
    
    var ciContext: CIContext!
    var image: CIImage!
    var decorator: PreviewCellDecorator!
    
    override var bounds: CGRect {
        willSet(newBounds) {
            decorator.boundWidth = newBounds.width
            decorator.boundHeight = newBounds.height
        }
    }
    
    init(image: CIImage) {
        super.init(frame: CGRect.zero, context: EAGLContext(api: .openGLES3)!)
        self.image = image
        ciContext = CIContext(eaglContext: context)
        decorator = PreviewCellDecorator(image: image, scale: .small)
        
        translatesAutoresizingMaskIntoConstraints = false
        let ratio = image.extent.width/image.extent.height
        widthAnchor.constraint(equalTo: heightAnchor, multiplier: ratio).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        let lastImage = decorator.composeLastImageWithSign()
        ciContext.draw(lastImage, in: rect.applying(CGAffineTransform(scaleX: UIScreen.main.scale, y: UIScreen.main.scale)), from: lastImage.extent)
    }
    
}

// MARK: - Pixellate
extension PreviewCell {
    
    func updateCrop(with normalizedRect: CGRect, identifier: CropArea) {
        decorator.updateCrop(with: normalizedRect, identifier: identifier)
        setNeedsDisplay()
    }
    
    
    func resetPixel() {
        decorator.resetPixel()
        setNeedsDisplay()
    }
    
    func setPixelScale(_ scale: PreviewPixellateScale) {
        decorator.updatePixelScale(scale)
    }
}

// MARK: - Sign
extension PreviewCell {
    
    func setSign(_ sign: String?) {
        decorator.setSign(sign)
        setNeedsDisplay()
    }
    
    func setSignAlign(_ align: PreviewAlignMode) {
        decorator.setSignAlign(align)
        setNeedsDisplay()
    }
}

class PreviewCellDecorator {
    
    var image: CIImage!
    var lastImage: CIImage!
    var pixellateScale: PreviewPixellateScale
    
    var cropRects: [CropArea: CGRect] = [CropArea: CGRect]()
    var pixellateImages = [PreviewPixellateScale: CIImage]()
    var boundWidth: CGFloat!
    var boundHeight: CGFloat!
    
    var sign: String?
    var signAlign:PreviewAlignMode = .middle
    var signImage: CIImage?
    
    /// Constructor for view
    init(image: CIImage, scale: PreviewPixellateScale) {
        self.image = image
        self.lastImage = image
        self.pixellateScale = scale
        
        preparePixellateImages(image)
    }
    
    /// Constructor for export
    convenience init(image: CIImage, cell: PreviewCell) {
        self.init(image: image, scale: cell.decorator.pixellateScale)
        boundWidth = image.extent.width
        boundHeight = image.extent.height
        
        if let sign = cell.decorator.sign {
            self.sign = sign
            self.signAlign = cell.decorator.signAlign
        }
        
        cropRects = cell.decorator.cropRects
    }
    
    func toUICoordinate(from rect: CGRect) -> CGRect {
        return rect.applying(CGAffineTransform(scaleX: boundWidth, y: boundHeight))
    }
    
    func renderCrop(with rect: CGRect)  {
        lastImage = pixellateImages[pixellateScale]!.cropped(to: toUICoordinate(from: rect).convertLTCToLBC(frameHeight: boundHeight)).composited(over: lastImage)
    }
    
    func updateCrop(with normalizedRect: CGRect, identifier: CropArea) {
        cropRects[identifier] = normalizedRect
        renderCrop(with: normalizedRect)
    }
    
    func preparePixellateImages(_ image: CIImage) {
        for scale in [PreviewPixellateScale.small, .middle, .large] {
            pixellateImages[scale] = applyPixel(image: image, pixelScale: scale)
        }
    }
    
    func applyPixel(image: CIImage, pixelScale: PreviewPixellateScale) -> CIImage {
        return image.applyingFilter("CIPixellate", parameters: ["inputScale": pixelScale.rawValue])
    }
    
    func resetPixel() {
        return lastImage = image
    }
    
    func updatePixelScale(_ scale: PreviewPixellateScale) {
        pixellateScale = scale
    }
    
    func setSign(_ sign: String?) {
        self.sign = sign
        updateSignImage()
    }
    
    func setSignAlign(_ align: PreviewAlignMode) {
        self.signAlign = align
        updateSignImage()
    }
    
    func composeLastImageWithSign() -> CIImage {
        guard let signImage = signImage else {
            return lastImage
        }
        
        let viewScale = CGFloat(1.0)
        let imageWidth = self.image.extent.width
        var translate:() -> CIImage
        switch signAlign {
        case .left:
            translate = {signImage.transformed(by: CGAffineTransform(translationX: 8*viewScale, y: 8*viewScale))}
        case .middle:
            translate = {signImage.transformed(by: CGAffineTransform(translationX: (imageWidth - signImage.extent.width)/2, y: 8*viewScale))}
        case .right:
            translate = {signImage.transformed(by: CGAffineTransform(translationX: (imageWidth - signImage.extent.width - 8*viewScale), y: 8*viewScale))}
        }
        
        return translate().composited(over: lastImage)
    }
    
    func composeImageForExport() -> CIImage {
        return rerenderAllPixelCrops()
    }
    
    func rerenderAllPixelCrops() -> CIImage {
        resetPixel()
        for (_, cropRect) in cropRects {
            renderCrop(with: cropRect)
        }
        return composeLastImageWithSign()
    }
    
    func updateSignImage() {
        guard let sign = sign else {
            signImage = nil
            return
        }
        
        let labelView = UILabel()
        labelView.textColor = UIColor.white
//        labelView.textColor = UIColor.red
        labelView.font = UIFont.systemFont(ofSize: PreviewConstants.signFontSize)
        labelView.text = sign
        labelView.sizeToFit()
        signImage = labelView.renderToCIImage()
    }
}
