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
    var decorator: PreviewCellDecorator?
    var imageManager = PHCachingImageManager.default() as! PHCachingImageManager
    var placeholderImage: CIImage!
    var loading = false
    var loadingSeq = Int32(0)
    
    var imageView: UIImageView!
    var pixelView: UIImageView!

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
        
        pixelView = UIImageView(frame: CGRect.zero)
        addSubview(pixelView)
        pixelView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
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
    
//    override func draw(_ rect: CGRect) {
//        let drawRect: CGRect = rect.applying(CGAffineTransform(scaleX: UIScreen.main.scale, y: UIScreen.main.scale+0.1))
//        if let decorator = decorator {
//            let lastImage = decorator.composeLastImageWithSign()
//            ciContext.draw(lastImage, in: drawRect, from: lastImage.extent)
//        } else {
////            ciContext.draw(placeholderImage, in: drawRect, from: drawRect)
//        }
//
//        //Very bad resolution.
////        ciContext.draw(lastImage, in: rect.applying(CGAffineTransform(scaleX: UIScreen.main.scale, y: UIScreen.main.scale)), from: lastImage.extent)
//    }
//
    func loadImage() {
        
//        let viewSize = bounds.size
//        let rect = CGRect(x: 20, y: 20, width: viewSize.width - 20*2, height: viewSize.height - 20*2)
//        mask(withRect: rect, inverse: false)
//
        guard loadingSeq == Int32(0) else {
            return
        }
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact
        let targetSize = CGSize(width: UIScreen.main.bounds.width, height: CGFloat(ciImage.asset.pixelHeight)/CGFloat(ciImage.asset.pixelWidth)*UIScreen.main.bounds.width)
        loadingSeq = imageManager.requestImage(for: ciImage.asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { (uiImage, config) in
            if let uiImage = uiImage {
                self.decorator = PreviewCellDecorator(image: CIImage(image: uiImage)!, scale: .small)
                self.decorator?.boundWidth = self.bounds.width
                self.decorator?.boundHeight = self.bounds.height
                self.imageView.image = self.decorator!.renderCache
                self.pixelView.image = UIImage(ciImage: self.decorator!.pixellateImages.first!.value)
//                self.bindDrawable()
                self.setNeedsDisplay()
            }
        }
    }
    
    func unloadImage() {
        decorator = nil
        loadingSeq = 0
//        self.deleteDrawable()
    }
    
}

// MARK: - Pixellate
extension PreviewCell {
    
    func updateCrop(with normalizedRect: CGRect, identifier: CropArea) {
        guard let decorator = decorator else {return}
        
//        decorator.updateCrop(with: normalizedRect, identifier: identifier)
        
        imageView.image = self.decorator!.renderCache
        let cropRect = normalizedRect.applying(CGAffineTransform(scaleX: bounds.width, y: bounds.height))
        let viewSize = bounds.size
//        let rect = CGRect(x: 20, y: 20, width: viewSize.width - 20*2, height: viewSize.height - 20*2)
        pixelView.mask(withRect: cropRect, inverse: false)

        
        setNeedsDisplay()
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

