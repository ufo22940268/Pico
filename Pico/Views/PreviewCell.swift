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
    
    var image: Image!
    var imageCrop: CGRect!
    var decorator: PreviewCellDecorator!
    var imageManager = PHCachingImageManager.default() as! PHCachingImageManager
    var placeholderImage: CIImage!
    var loading = false
    var loadingSeq = Int32(0)
    
    var imageView: CropImageView!
    var pixelView: PixelView!
    var signView: UILabel!
    var pixelScale : PreviewPixellateScale = .small
    
    override var bounds: CGRect {
        willSet(newBounds) {
            if let decorator = decorator {
                decorator.boundWidth = newBounds.width
                decorator.boundHeight = newBounds.height
            }
        }
    }
    
    init(image: Image, imageCrop: CGRect) {
        super.init(frame: CGRect.zero)
        self.decorator = PreviewCellDecorator(scale: .small)
        self.image = image
        self.imageCrop = imageCrop
        translatesAutoresizingMaskIntoConstraints = false
        let pixelCropSize = imageCrop.size.applying(CGAffineTransform(scaleX: image.assetSize.width, y: image.assetSize.height))
        let ratio = pixelCropSize.width/pixelCropSize.height
        widthAnchor.constraint(equalTo: heightAnchor, multiplier: ratio).isActive = true
        
        setupPlaceholder()
        
        imageView = CropImageView(frame: CGRect.zero)
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
        imageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 1).isActive = true
        imageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        imageView.isOpaque = false
        imageView.contentMode = .scaleToFill
        
        pixelView = PixelView(frame: CGRect.zero)
        addSubview(pixelView)
        pixelView.contentMode = .scaleToFill
        pixelView.translatesAutoresizingMaskIntoConstraints = false
        pixelView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
        pixelView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 1).isActive = true
        pixelView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        pixelView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        
        signView = UILabel(frame: CGRect.zero)
        signView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

// MARK: - Pixellate
extension PreviewCell {
        
    func updatePixelCrop(with normalizedRect: CGRect, identifier: CropArea) {
        guard decorator.isImageLoaded() else {return}
        
        decorator.updatePixelCrop(with: normalizedRect, identifier: identifier)
    }
    
    func updatePixelRects() {
        guard decorator.isImageLoaded() else {return}
        
        pixelView.updatePixelRects(Array(decorator.cropRects.values))
    }
    
    
    func displaySign() {
        guard decorator.isImageLoaded() else {return}
    
        if decorator.sign == nil {
            signView.removeFromSuperview()
        } else {
            signView.removeFromSuperview()
            addSubview(signView)
            
            decorator.setupLabel(signView, for: .render)
            
            signView.sizeToFit()
            signView.widthAnchor.constraint(equalToConstant: signView.bounds.width).isActive = true
            signView.heightAnchor.constraint(equalToConstant: signView.bounds.height).isActive = true
            let gap = CGFloat(8)
            signView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -gap).isActive = true
            switch decorator.signAlign {
            case .left:
                signView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: gap).isActive = true
            case .middle:
                signView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0).isActive = true
            case .right:
                signView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -gap).isActive = true
            }
        }
    }
    
    func removeCrop(by identifier: CropArea) {
        guard decorator.isImageLoaded() else {return}
        decorator.removePixelCrop(by: identifier)
    }
    
    func sync(with areas: [CropArea: CGRect]) {
        decorator.sync(with: areas)
    }
    
    func resetPixel() {
        decorator?.resetPixel()
        setNeedsDisplay()
    }
    
    func updatePixelImageInPixelView() {
        guard decorator.isImageLoaded() else {return}
        self.pixelView.image = pixelImage
    }
    
    func setPixelScale(_ scale: PreviewPixellateScale) {
        pixelScale = scale
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

extension PreviewCell : LoadingPlaceholder {
    
    func contentViewVisible(_ show: Bool) {
        imageView.isHidden = !show
        pixelView.isHidden = !show
        signView.isHidden = !show
    }
}

extension PreviewCell : RecycleCell {
    
    func getFrame() -> CGRect {
        return frame
    }
    
    var pixelImage:UIImage {
        return self.decorator!.pixellateImages[pixelScale]!.convertToUIImage()
    }
    
    func loadImage() { 
        guard loadingSeq == Int32(0) else {
            return
        }
        
        showPlaceholder()
        loadingSeq = image.resolve(completion: { (uiImage) in
            if let uiImage = uiImage {
//                var ciImage: CIImage = CIImage(image: uiImage)!
//                ciImage = ciImage.cropped(to: self.imageCrop.applying(CGAffineTransform(scaleX: ciImage.extent.width, y: ciImage.extent.height)))
//                ciImage = ciImage.transformed(by: CGAffineTransform(scaleX: UIScreen.main.pixelSize.width/ciImage.extent.width, y: UIScreen.main.pixelSize.width/ciImage.extent.width))
                self.decorator.setImage(CIImage(image: uiImage)!)
                self.decorator?.boundWidth = self.bounds.width
                self.decorator?.boundHeight = self.bounds.height
                UIView.transition(with: self.imageView, duration: 0.3, options: .transitionCrossDissolve, animations: {
                    self.imageView.image = uiImage
                    self.imageView.cropRect = self.imageCrop
                    self.pixelView.cropRect = self.imageCrop
                }, completion: { success in
                    self.updatePixelRects()
                    self.updatePixelImageInPixelView()
                })
            }
            self.showContentView()
            self.setNeedsDisplay()
        }, targetWidth: UIScreen.main.pixelSize.width, resizeMode: .fast, contentMode: .aspectFill)
    }
    
    func unloadImage() {
        decorator.releaseImage()
        loadingSeq = 0
        self.imageView.image = nil
        self.pixelView.image = nil
    }
}
