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

class PreviewCell: GLKView {
    
    var ciContext: CIContext!
    var image: Image!
    var decorator: PreviewCellDecorator?
    var imageManager = PHCachingImageManager.default() as! PHCachingImageManager
    var placeholderImage: CIImage!
    var loading = false
    var loadingSeq = Int32(0)

    override var bounds: CGRect {
        willSet(newBounds) {
            if let decorator = decorator {
                decorator.boundWidth = newBounds.width
                decorator.boundHeight = newBounds.height
            }
        }
    }
    
    init(image: Image) {
        super.init(frame: CGRect.zero, context: EAGLContext(api: .openGLES3)!)
        self.image = image
        ciContext = CIContext(eaglContext: context)
//        decorator = PreviewCellDecorator(image: image, scale: .small)
        
        translatesAutoresizingMaskIntoConstraints = false
        let ratio = CGFloat(image.asset.pixelWidth)/CGFloat(image.asset.pixelHeight)
        widthAnchor.constraint(equalTo: heightAnchor, multiplier: ratio).isActive = true

        placeholderImage = CIImage(color: CIColor(color: UIColor.green))
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        let drawRect: CGRect = rect.applying(CGAffineTransform(scaleX: UIScreen.main.scale, y: UIScreen.main.scale+0.1))
        print("decorator: \(decorator)")
        if let decorator = decorator {
            let lastImage = decorator.composeLastImageWithSign()
            ciContext.draw(lastImage, in: drawRect, from: lastImage.extent)
//        } else {
//            ciContext.draw(placeholderImage, in: drawRect, from: drawRect)
        }
     
        //Very bad resolution.
//        ciContext.draw(lastImage, in: rect.applying(CGAffineTransform(scaleX: UIScreen.main.scale, y: UIScreen.main.scale)), from: lastImage.extent)
    }
    
    func loadImage() {
        guard loadingSeq == Int32(0) else {
            return
        }
        
        print("loadImage")
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        loadingSeq = imageManager.requestImage(for: image.asset, targetSize: UIScreen.main.bounds.size, contentMode: .aspectFill, options: options) { (uiImage, config) in
            if let uiImage = uiImage {
                self.decorator = PreviewCellDecorator(image: CIImage(image: uiImage)!, scale: .small)
                print("self.decorator: \(self.decorator)")
                self.setNeedsDisplay()
            }
        }
    }
    
    func unloadImage() {
        decorator = nil
        loadingSeq = 0
    }
    
}

// MARK: - Pixellate
extension PreviewCell {
    
    func updateCrop(with normalizedRect: CGRect, identifier: CropArea) {
        decorator?.updateCrop(with: normalizedRect, identifier: identifier)
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

