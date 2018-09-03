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
        decorator = PreviewCellDecorator(image: image, scale: .small, boundWidth: bounds.width)
        
        translatesAutoresizingMaskIntoConstraints = false
        let ratio = image.extent.width/image.extent.height
        widthAnchor.constraint(equalTo: heightAnchor, multiplier: ratio).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        let lastImage = decorator.lastImage!
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

class PreviewCellDecorator {
    
    var image: CIImage!
    var lastImage: CIImage!
    var pixellateScale: PreviewPixellateScale
    
    var cropRects: [CropArea: CGRect] = [CropArea: CGRect]()
    var pixellateImages = [PreviewPixellateScale: CIImage]()
    var boundWidth: CGFloat!
    var boundHeight: CGFloat!
    
    init(image: CIImage, scale: PreviewPixellateScale, boundWidth: CGFloat) {
        self.image = image
        self.lastImage = image
        self.pixellateScale = scale
        self.boundWidth = boundWidth
        
        preparePixellateImages(image)
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
}
