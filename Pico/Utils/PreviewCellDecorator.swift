//
//  PreviewCellDecorator.swift
//  Pico
//
//  Created by Frank Cheng on 2018/9/4.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import GLKit

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
    var fontSize = PreviewConstants.signFontSize
    
    /// Constructor for view
    init(image: CIImage, scale: PreviewPixellateScale) {
        self.image = image
        self.lastImage = image
        self.pixellateScale = scale
        
        preparePixellateImages(image)
    }
    
    /// Constructor for export
    convenience init(image: CIImage, cell: PreviewCell) {
        self.init(image: image, scale: cell.decorator!.pixellateScale)
        boundWidth = image.extent.width
        boundHeight = image.extent.height
        
        if let sign = cell.decorator!.sign {
            self.sign = sign
            self.signAlign = cell.decorator!.signAlign
        }
        
        cropRects = cell.decorator!.cropRects
        fontSize = PreviewConstants.signFontSize*(image.extent.width/UIScreen.main.bounds.width)
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
        rerenderAllPixelCrops()
        updateSignImage()
        return composeLastImageWithSign()
    }
    
    func rerenderAllPixelCrops() {
        resetPixel()
        for (_, cropRect) in cropRects {
            renderCrop(with: cropRect)
        }
    }
    
    func updateSignImage() {
        guard let sign = sign else {
            signImage = nil
            return
        }
        
        let labelView = UILabel()
        labelView.textColor = UIColor.white
        labelView.font = UIFont.systemFont(ofSize: fontSize)
        labelView.text = sign
        labelView.sizeToFit()
        signImage = labelView.renderToCIImage()
    }
}
