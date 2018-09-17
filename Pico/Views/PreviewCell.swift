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
    var imageManager = PHCachingImageManager.default()
    
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
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        imageManager.requestImage(for: image.asset, targetSize: UIScreen.main.bounds.size, contentMode: .aspectFill, options: options) { (uiImage, config) in
            if let uiImage = uiImage {
                self.decorator = PreviewCellDecorator(image: CIImage(image: uiImage)!, scale: .small)
                self.setNeedsDisplay()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        if let decorator = decorator {
            let lastImage = decorator.composeLastImageWithSign()
            ciContext.draw(lastImage, in: rect.applying(CGAffineTransform(scaleX: UIScreen.main.scale, y: UIScreen.main.scale+0.1)), from: lastImage.extent)
        }
     
        //Very bad resolution.
//        ciContext.draw(lastImage, in: rect.applying(CGAffineTransform(scaleX: UIScreen.main.scale, y: UIScreen.main.scale)), from: lastImage.extent)
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

