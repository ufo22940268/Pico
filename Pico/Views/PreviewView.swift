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
    var rawImages: [UIImage]!
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
    
    fileprivate func drawSign(canvas: inout CIImage, signImage: CIImage?, scale:CGFloat = 1) {
        if let signImage = signImage {
            var translate:() -> CIImage
            let resultWidth = canvas.extent.width
            switch align {
            case .left:
                translate = {signImage.transformed(by: CGAffineTransform(translationX: 8*scale, y: 8*scale))}
            case .middle:
                translate = {signImage.transformed(by: CGAffineTransform(translationX: (resultWidth - signImage.extent.width)/2, y: 8*scale))}
            case .right:
                translate = {signImage.transformed(by: CGAffineTransform(translationX: (resultWidth - signImage.extent.width - 8*scale), y: 8*scale))}
            }
            canvas = translate().composited(over: canvas)
        }
    }
    
    fileprivate func pixellate(ciImage: inout CIImage, forExport: Bool, transformCrop: CGAffineTransform? = nil) {
        let pixellateImage = ciImage.applyingFilter("CIPixellate", parameters: ["inputScale": pixellateScale])
        for index in 0..<crops.count {
            if !forExport && crops[index].rendered != false {
                continue
            }
            
            let crop = crops[index]
            var rect: CGRect = crop.rect
            if let transformCrop = transformCrop {
                rect = rect.applying(transformCrop)
            }
            ciImage = pixellateImage.cropped(to: rect).applyingFilter("CISourceOverCompositing", parameters: ["inputBackgroundImage": ciImage])
            crops[index].setRendered(rendered: true)
        }
    }
    
    override func draw(_ rect: CGRect) {
        let contextRect = rect.applying(CGAffineTransform(scaleX: UIScreen.main.scale, y: UIScreen.main.scale))

        var result = previousImage!
        
        pixellate(ciImage: &result, forExport: false)
        
        previousImage = result
        drawSign(canvas: &result, signImage: signImage)
        ciContext.draw(result, in: contextRect, from: result.extent)
    }
    
    func convertUIRectToCIRect(uiRect: CGRect) -> CGRect {
        var ciRect = uiRect.applying(CGAffineTransform(scaleX: CGFloat(image.extent.width)/frame.size.width, y: CGFloat(image.extent.height)/frame.size.height))
        ciRect.origin.y = CGFloat(image.extent.height) - ciRect.origin.y - ciRect.size.height
        return ciRect
    }
    
   
    fileprivate func scalaToFill(image: CIImage, width: CGFloat) -> CIImage {
        let scale = width * UIScreen.main.scale / image.extent.width
        return image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }

    func concateImages(images: [CIImage], fillContainer: Bool = true) -> CIImage {
        var fillWidth:CGFloat
        
        if fillContainer {
            /// TODO This is not real container width.
            fillWidth = UIScreen.main.bounds.width
        } else {
            fillWidth = images.max(by: { (c1, c2) -> Bool in
                return c1.extent.width < c2.extent.width
            })!.extent.width
        }
        
        var scaledImages = images.map { scalaToFill(image: $0, width: fillWidth) }
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

        return canvas
    }
    
    func renderCache(frameView: FrameView) -> UIImage {
        let frameRects = frameView.frameRects
        var canvas = concateImages(images: rawImages.map{CIImage(image: $0)!}, fillContainer: false)
        
        UIGraphicsBeginImageContext(canvas.extent.size)
        
        let imageScale = canvas.extent.width/(frame.size.width*UIScreen.main.scale)
        let viewScale = canvas.extent.width/frame.size.width
        let fromRawToConcateScale = canvas.extent.width/rawImages.min(by: {$0.size.width < $1.size.width})!.size.width
        
        let renderer = PreviewRenderer(imageScale: imageScale)
        pixellate(ciImage: &canvas, forExport: true, transformCrop: CGAffineTransform(scaleX: imageScale, y: imageScale))
        
        if let sign = sign {
            let labelView = UILabel()
            labelView.textColor = UIColor.white
            labelView.font = UIFont.systemFont(ofSize: 80)
            labelView.text = sign
            labelView.sizeToFit()
            let labelImage = labelView.renderToCIImage()
            drawSign(canvas: &canvas, signImage: labelImage, scale: imageScale)
        }
        
        let canvasImage = canvas.convertToUIImage()
        canvasImage.draw(at: CGPoint.zero)
        
        let frameScale = canvas.extent.width/frameView.frame.width
        renderer.drawFrameRects(rect: canvas.extent, frameType: frameView.frameType, frameRects: frameRects.map{ $0.applying(CGAffineTransform(scaleX: fromRawToConcateScale, y: fromRawToConcateScale))}, scale: frameScale)

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
