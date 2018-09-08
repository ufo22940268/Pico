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
        ciContext.draw(lastImage, in: rect.applying(CGAffineTransform(scaleX: UIScreen.main.scale, y: UIScreen.main.scale+0.1)), from: lastImage.extent)
     
        //Very bad resolution.
//        ciContext.draw(lastImage, in: rect.applying(CGAffineTransform(scaleX: UIScreen.main.scale, y: UIScreen.main.scale)), from: lastImage.extent)
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

