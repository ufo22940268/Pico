//
//  PreviewView.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/17.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit
import GLKit

struct CropArea {
    init(rect: CGRect) {
        self.rect = rect
    }
    var rect: CGRect!
    var rendered = false
    
    mutating func setRendered(rendered: Bool) {
        self.rendered = rendered
    }
}

protocol PreviewViewDelegate {
    func onSignChanged(sign: String?)
}

class PreviewView: GLKView {

    var previousImage: CIImage!
    static let maximumPixellateScale = 50
    static let minimumPixellateScale = 7
    var pixellateScale = Float(maximumPixellateScale - minimumPixellateScale)*0.5
    var sign: String? {
        willSet(newSign) {
            previewDelegate?.onSignChanged(sign: newSign)
            let sign = newSign ?? ""
            labelView.text = sign
            labelView.sizeToFit()
            
            guard labelView.frame.size != CGSize.zero else {
                signImage = nil
                return
            }
            UIGraphicsBeginImageContext(labelView.frame.size)
            labelView.layer.render(in: UIGraphicsGetCurrentContext()!)
            signImage = CIImage(image: UIGraphicsGetImageFromCurrentImageContext()!)
            UIGraphicsEndImageContext()
        }
    }
    var align = PreviewAlignMode.middle
    var previewDelegate: PreviewViewDelegate?
    var signImage: CIImage?
    
    var image: CIImage! {
        willSet(newImage) {
            previousImage = newImage
        }
    }
    
    var selection: CGRect?
    var ciContext: CIContext!
    var crops: [CropArea] = [CropArea]()
    var labelView: UILabel!
    
    override func awakeFromNib() {
        context = EAGLContext(api: .openGLES3)!
        ciContext = CIContext(eaglContext: context)
        
        labelView = UILabel()
        labelView.textColor = UIColor.white
        labelView.font = UIFont.systemFont(ofSize: 50)
    }
    
    fileprivate func drawSign(_ result: inout CIImage) {
        if let signImage = signImage {
            var translate:() -> CIImage
            let resultWidth = result.extent.width
            switch align {
            case .left:
                translate = {signImage.transformed(by: CGAffineTransform(translationX: 8, y: 8))}
            case .middle:
                translate = {signImage.transformed(by: CGAffineTransform(translationX: (resultWidth - signImage.extent.width)/2, y: 8))}
            case .right:
                translate = {signImage.transformed(by: CGAffineTransform(translationX: resultWidth - signImage.extent.width - 8, y: 8))}
            }
            result = translate().composited(over: result)
        }
    }
    
    override func draw(_ rect: CGRect) {
        let contextRect = rect.applying(CGAffineTransform(scaleX: UIScreen.main.scale, y: UIScreen.main.scale))

        let pixellateImage = image.applyingFilter("CIPixellate", parameters: ["inputScale": pixellateScale])
        var result = previousImage!
        for index in 0..<crops.count where crops[index].rendered == false {
            let crop = crops[index]
            result = pixellateImage.cropped(to: crop.rect).applyingFilter("CISourceOverCompositing", parameters: ["inputBackgroundImage": result])
            crops[index].setRendered(rendered: true)
        }
        
        
        previousImage = result
        drawSign(&result)
        ciContext.draw(result, in: contextRect, from: result.extent)
        
    }
    
    func convertUIRectToCIRect(uiRect: CGRect) -> CGRect {
        var ciRect = uiRect.applying(CGAffineTransform(scaleX: CGFloat(image.extent.width)/frame.size.width, y: CGFloat(image.extent.height)/frame.size.height))
        ciRect.origin.y = CGFloat(image.extent.height) - ciRect.origin.y - ciRect.size.height
        return ciRect
    }
    
   
    func scalaToFillContainer(image: CIImage) -> CIImage {
        let scale = UIScreen.main.bounds.width * UIScreen.main.scale / image.extent.width
        return image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }

    func concateImages(images: [CIImage]) {
        var scaledImages = images.map { scalaToFillContainer(image: $0) }
        scaledImages.forEach { print($0.extent) }
        let canvasHeight = scaledImages.reduce(0) { (r, img)  in
            return r + img.extent.height
        }
        var canvas = scaledImages.last!
        let canvasRect = canvas.extent.applying(CGAffineTransform(scaleX: 1, y: canvasHeight/canvas.extent.height))
        canvas = canvas.clampedToExtent().cropped(to: canvasRect)
        var height = scaledImages.last!.extent.height
        for im in scaledImages[0..<images.count - 1].reversed() {
            canvas = im.transformed(by: CGAffineTransform(translationX: 0.0, y: height)).composited(over: canvas)
            height = height + im.extent.height
        }
        
        image = canvas
    }
    
    func renderCache() -> UIImage {
        UIGraphicsBeginImageContext(snapshot.size)
        snapshot.draw(at: CGPoint.zero)
        
        let context = UIGraphicsGetCurrentContext()!
        for subview in subviews {
            context.translateBy(x: subview.frame.origin.x, y: subview.frame.origin.y)
            subview.layer.draw(in: context)
        }
        
        let cache = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return cache
    }
}

// MARK: - Pixellate functions
extension PreviewView {
    
    func undo() {
        if crops.count > 0 {
            crops.removeLast()
            rerenderCrops()
        }
    }
    
    func addPixellate(uiRect: CGRect) {
        let ciRect = convertUIRectToCIRect(uiRect: uiRect)
        crops.append(CropArea(rect: ciRect))
    }
    
    func updatePixellate(uiRect: CGRect) {
        if var lastCrop = crops.last {
            let ciRect = convertUIRectToCIRect(uiRect: uiRect)
            lastCrop.rect = ciRect
            lastCrop.rendered = false
        }
    }
    
    func updatePixellateSize(percent: Float) {
        pixellateScale = Float(PreviewView.maximumPixellateScale - PreviewView.minimumPixellateScale)*percent
    }
    
    func rerenderCrops() {
        previousImage = image
        for index in 0..<crops.count {
            crops[index].rendered = false
        }
    }
    
}

// MARK: - Signature
extension PreviewView {
    func setSign(sign: String) {
        self.sign = sign
    }
    
    func clearSign() {
        self.sign = nil
    }
    
    func setAlign(align: PreviewAlignMode) {
        self.align = align
    }
}
