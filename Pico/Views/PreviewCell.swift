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
import PhotosUI

extension UIView {
    
    func mask(withRect rect: CGRect, inverse: Bool = false) {
        let path = UIBezierPath(rect: rect)
        let maskLayer = CAShapeLayer()
        
        if inverse {
            path.append(UIBezierPath(rect: self.bounds))
            maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        }
        
        maskLayer.path = path.cgPath
        
        self.layer.mask = maskLayer
    }
    
    func mask(withPath path: UIBezierPath, inverse: Bool = false) {
        let path = path
        let maskLayer = CAShapeLayer()
        
        if inverse {
            path.append(UIBezierPath(rect: self.bounds))
            maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        }
        
        maskLayer.path = path.cgPath
        
        self.layer.mask = maskLayer
    }
}


class PreviewCell: UIView {
    
    var ciContext: CIContext!
    var ciImage: Image!
    var decorator: PreviewCellDecorator!
    var imageManager = PHCachingImageManager.default() as! PHCachingImageManager
    var placeholderImage: CIImage!
    var loading = false
    var loadingSeq = Int32(0)
    
    var imageView: UIImageView!
    var pixelView: PixelView!
    
    override var bounds: CGRect {
        willSet(newBounds) {
            if let decorator = decorator {
                decorator.boundWidth = newBounds.width
                decorator.boundHeight = newBounds.height
            }
        }
    }
    
    init(image: Image, ciContext: CIContext, eaglContext: EAGLContext) {
        super.init(frame: CGRect.zero)
        self.decorator = PreviewCellDecorator(scale: .small)
        self.ciImage = image
        self.ciContext = ciContext
        translatesAutoresizingMaskIntoConstraints = false
        let ratio = CGFloat(image.asset.pixelWidth)/CGFloat(image.asset.pixelHeight)
        widthAnchor.constraint(equalTo: heightAnchor, multiplier: ratio).isActive = true
        
        backgroundColor = UIColor.yellow
        
        imageView = UIImageView(frame: CGRect.zero)
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
        imageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 1).isActive = true
        imageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        imageView.isOpaque = false
        
        pixelView = PixelView(frame: CGRect.zero)
        addSubview(pixelView)
        pixelView.translatesAutoresizingMaskIntoConstraints = false
        pixelView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
        pixelView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 1).isActive = true
        pixelView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        pixelView.topAnchor.constraint(equalTo: topAnchor).isActive = true
//        placeholderImage = CIImage(color: CIColor(color: UIColor.green))
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func loadImage() {
        guard loadingSeq == Int32(0) else {
            return
        }
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact
        let targetSize = CGSize(width: UIScreen.main.bounds.width, height: CGFloat(ciImage.asset.pixelHeight)/CGFloat(ciImage.asset.pixelWidth)*UIScreen.main.bounds.width)
        loadingSeq = imageManager.requestImage(for: ciImage.asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { (uiImage, config) in
            if let uiImage = uiImage {
                self.decorator.setImage(CIImage(image: uiImage)!)
                self.decorator?.boundWidth = self.bounds.width
                self.decorator?.boundHeight = self.bounds.height
                self.imageView.image = UIImage(ciImage: self.decorator.composeLastImageWithSign())
                self.pixelView.image = UIImage(ciImage: self.decorator!.pixellateImages.first!.value)
                self.updateCrop()
                self.setNeedsDisplay()
            }
        }
    }
    
    func unloadImage() {
        decorator.releaseImage()
        loadingSeq = 0
    }
    
}

// MARK: - Pixellate
extension PreviewCell {
        
    func updateCrop(with normalizedRect: CGRect, identifier: CropArea) {
        guard decorator.isImageLoaded() else {return}
        
        decorator.updateCrop(with: normalizedRect, identifier: identifier)
        updateCrop()
    }
    
    func updateCrop() {
        guard decorator.isImageLoaded() else {return}

        pixelView.updatePixelRects(Array(decorator.cropRects.values))
        setNeedsDisplay()
    }
    
    func removeCrop(by identifier: CropArea) {
        guard decorator.isImageLoaded() else {return}
        decorator.removeCrop(by: identifier)
    }
    
    func sync(with areas: [CropArea: CGRect]) {
        decorator.sync(with: areas)
    }
    
    
    func resetPixel() {
        decorator?.resetPixel()
        setNeedsDisplay()
    }
    
    func setPixelScale(_ scale: PreviewPixellateScale) {
        decorator?.updatePixelScale(scale)
    }
}

// MARK: - Sign
extension PreviewCell {
    
    func setSign(_ sign: String?) {
        decorator?.setSign(sign)
        setNeedsDisplay()
    }
    
    func setSignAlign(_ align: PreviewAlignMode) {
        decorator?.setSignAlign(align)
        setNeedsDisplay()
    }
}

