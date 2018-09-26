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
    
    var imageView: UIImageView!
    var pixelView: PixelView!
    var signView: UILabel!
    
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
        
        imageView = UIImageView(frame: CGRect.zero)
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
        
    func updateCrop(with normalizedRect: CGRect, identifier: CropArea) {
        guard decorator.isImageLoaded() else {return}
        
        decorator.updateCrop(with: normalizedRect, identifier: identifier)
        displayPixel()
    }
    
    func displayPixel() {
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
    
    func loadImage() {
        guard loadingSeq == Int32(0) else {
            return
        }
        
        showPlaceholder()
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact
        loadingSeq = image.resolve(completion: { (uiImage) in
            if let uiImage = uiImage {
                let ciImage: CIImage = CIImage(image: uiImage)!.cropped(to: self.imageCrop.applying(CGAffineTransform(scaleX: uiImage.size.width, y: uiImage.size.height)))
                self.decorator.setImage(ciImage)
                self.decorator?.boundWidth = self.bounds.width
                self.decorator?.boundHeight = self.bounds.height
                self.imageView.image = self.decorator.lastImage.convertToUIImage()
                self.pixelView.image = UIImage(ciImage: self.decorator!.pixellateImages.first!.value)
                self.displayPixel()
            }
            self.showContentView()
            self.setNeedsDisplay()
            self.setNeedsLayout()
        }, targetWidth: UIScreen.main.pixelSize.width, resizeMode: .fast, contentMode: .aspectFill)
    }
    
    func unloadImage() {
        decorator.releaseImage()
        loadingSeq = 0
        self.imageView.image = nil
        self.pixelView.image = nil
    }
}
