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
    
    enum Context {
        case render, export
    }
    
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
    var forExport = false
    
    var lastUIImage: UIImage? {
        guard let lastImage = lastImage else {return nil}
        return UIImage(ciImage: lastImage)
    }
    
    /// Constructor for view
    init(scale: PreviewPixellateScale) {
        self.pixellateScale = scale
    }
    
    
    /// Constructor for export
    convenience init(image: CIImage, cell: PreviewCell) {
        self.init(scale: cell.decorator!.pixellateScale)
        forExport = true
        boundWidth = image.extent.width
        boundHeight = image.extent.height
        
        if let sign = cell.decorator!.sign {
            self.sign = sign
            self.signAlign = cell.decorator!.signAlign
        }
        
        cropRects = cell.decorator!.cropRects
        fontSize = PreviewConstants.signFontSize*(image.extent.width/UIScreen.main.bounds.width)
        setImage(image)
    }

    func isImageLoaded() -> Bool {
        return self.lastImage != nil
    }
    
    func setImage(_ image: CIImage) {
        self.image = image
        self.lastImage = image
        
        preparePixellateImages(image)
    }
    
    func releaseImage() {
        self.image = nil
        self.lastImage = nil
        pixellateImages.removeAll()
    }
    
    
    func toUICoordinate(from rect: CGRect) -> CGRect {
        return rect.applying(CGAffineTransform(scaleX: imageSize.width, y: imageSize.height))
    }
    
    var imageSize: CGSize {
        return lastImage.extent.size
    }
    
    func renderPixelCrop(with rect: CGRect)  {
        lastImage = pixellateImages[pixellateScale]!
            .cropped(to: toUICoordinate(from: rect).convertLTCToLBC(frameHeight: imageSize.height))
            .composited(over: lastImage)
    }
    
    func updatePixelCrop(with normalizedRect: CGRect, identifier: CropArea) {
        cropRects[identifier] = normalizedRect
        if forExport {            
            renderPixelCrop(with: normalizedRect)
        }
    }
    
    func removePixelCrop(by identifier: CropArea) {
        cropRects.removeValue(forKey: identifier)
    }
    
    func sync(with areas: [CropArea:CGRect]) {
        cropRects.removeAll()
        for (area, cropRect) in areas {
            cropRects[area] = cropRect
        }
    }
    
    func preparePixellateImages(_ image: CIImage) {
        for scale in [PreviewPixellateScale.small, .middle, .large] {
            pixellateImages[scale] = pixelImage(image: image, pixelScale: scale)
        }
    }
    
    var exportRatio: CGFloat {
        return lastImage.extent.width/UIScreen.main.pixelSize.width
    }
    
    func pixelImage(image: CIImage, pixelScale: PreviewPixellateScale) -> CIImage {
        let scale = Int(!forExport ? CGFloat(pixelScale.rawValue) : CGFloat(pixelScale.rawValue)*exportRatio)
        let compatibleSize = CGSize(width: Int(image.extent.width) - Int(image.extent.width)%scale, height: Int(image.extent.height) - Int(image.extent.height)%scale)
        let compatibleImage = image.cropped(to: CGRect(origin: image.extent.origin, size: compatibleSize))
        
//        let inputCenter = forExport ? CIVector(cgPoint: CGPoint(x: compatibleImage.extent.midX, y: compatibleImage.extent.midY)) : CIVector(cgPoint: CGPoint(x: UIScreen.main.pixelBounds.midX, y: UIScreen.main.pixelBounds.midY))
        
        let inputCenter = CIVector(cgPoint: CGPoint(x: Int(compatibleImage.extent.width)/scale/2*scale, y: Int(compatibleImage.extent.height)/scale/2*scale))
        
        var pixelImage = compatibleImage.applyingFilter("CIPixellate", parameters: ["inputScale": scale]).resetOffset()
        pixelImage = pixelImage.transformed(by: CGAffineTransform(scaleX: image.extent.width/pixelImage.extent.width, y: image.extent.height/pixelImage.extent.height))
//        pixelImage = pixelImage.cropped(to: CGRect(origin: CGPoint.zero, size: lastImage.extent.size))
        
        return pixelImage
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
            renderPixelCrop(with: cropRect)
        }
    }
    
    func updateSignImage() {
        guard sign != nil && sign != "" else {
            signImage = nil
            return
        }
        
        let labelView = UILabel()
        setupLabel(labelView, for: .export)
        signImage = labelView.renderToCIImage()
    }
    
    func setupLabel(_ label: UILabel, for context: Context) {
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: fontSize)
        label.text = sign
        label.sizeToFit()
    }
}
