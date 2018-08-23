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

protocol PreviewViewDelegate: class {
    func onSignChanged(sign: String?)
}

enum PreviewPixellateScale: Int {
    case small = 7
    case middle = 14
    case large = 21
}

class PreviewView: GLKView {

    var previousImage: CIImage!
    var uiImages: [UIImage]!
    var selectedPixelScale = PreviewPixellateScale.small
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
    weak var previewDelegate: PreviewViewDelegate?
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
    var pixellateImages = [PreviewPixellateScale: CIImage]()
    
    var pixellateImage: CIImage?
    var signFontSize = CGFloat(20)
    
    override func awakeFromNib() {
        context = EAGLContext(api: .openGLES3)!
        ciContext = CIContext(eaglContext: context)
        
        labelView = UILabel()
        labelView.textColor = UIColor.white
        labelView.font = UIFont.systemFont(ofSize: signFontSize*UIScreen.main.scale)
    }
    
    fileprivate func drawSign(canvas: inout CIImage, signImage: CIImage?, viewScale:CGFloat = 1, forExport: Bool = false) {
        if var signImage = signImage {
            var translate:() -> CIImage
            let resultWidth = canvas.extent.width
            if !forExport {
                signImage = signImage.transformed(by: CGAffineTransform(scaleX: 1/UIScreen.main.scale, y: 1/UIScreen.main.scale))
            }
            switch align {
            case .left:
                translate = {signImage.transformed(by: CGAffineTransform(translationX: 8*viewScale, y: 8*viewScale))}
            case .middle:
                translate = {signImage.transformed(by: CGAffineTransform(translationX: (resultWidth - signImage.extent.width)/2, y: 8*viewScale))}
            case .right:
                translate = {signImage.transformed(by: CGAffineTransform(translationX: (resultWidth - signImage.extent.width - 8*viewScale), y: 8*viewScale))}
            }
            canvas = translate().composited(over: canvas)
        }
    }
    
    fileprivate func pixellate(ciImage: CIImage, forExport: Bool, transformCrop: CGAffineTransform? = nil, pixellateImage: CIImage) -> CIImage {
        var prev = ciImage
        for index in 0..<crops.count {
            if !forExport && crops[index].rendered != false {
                continue
            }
            
            let crop = crops[index]
            var rect: CGRect = crop.rect.applying(transform.scaledBy(x: bounds.width, y: bounds.height))
            if let transformCrop = transformCrop {
                rect = rect.applying(transformCrop)
            }
            prev = pixellateImage.cropped(to: rect).applyingFilter("CISourceOverCompositing", parameters: ["inputBackgroundImage": prev])
        }
        return prev
    }
    
    override func draw(_ rect: CGRect) {
        let contextRect = rect.applying(CGAffineTransform(scaleX: UIScreen.main.scale, y: UIScreen.main.scale))

        var result = previousImage!
        
        previousImage = result
        
        drawSign(canvas: &result, signImage: signImage)
        ciContext.draw(result, in: contextRect, from: result.extent)
        
        if let pixellateImage = pixellateImage {
            ciContext.draw(pixellateImage, in: contextRect, from: pixellateImage.extent)
        }
    }
    
    func convertUIRectToCIRect(uiRect: CGRect) -> CGRect {
        return uiRect.convertLTCToLBC(frameHeight: 1)
    }
    
   
    fileprivate func scalaToFill(image: CIImage, width: CGFloat) -> CIImage {
        let scale = width / image.extent.width
        return image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }

    func concateImages(images: [CIImage], fillContainer: Bool = true) -> CIImage {
        var fillWidth:CGFloat
        
        if fillContainer {
            /// TODO This is not real container width.
            fillWidth = UIScreen.main.bounds.width
        } else {
            fillWidth = images.min(by: { (c1, c2) -> Bool in
                return c1.extent.width < c2.extent.width
            })!.extent.width
        }
        
        var scaledImages = images.map { scalaToFill(image: $0, width: fillWidth) }
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
        
        preparePixellateImages(canvas)

        return canvas
    }
    
    func applyPixel(image: CIImage, pixelScale: PreviewPixellateScale) -> CIImage {
        return image.applyingFilter("CIPixellate", parameters: ["inputScale": pixelScale.rawValue])
    }
    
    func preparePixellateImages(_ image: CIImage) {
        for scale in [PreviewPixellateScale.small, .middle, .large] {
            pixellateImages[scale] = applyPixel(image: image, pixelScale: scale)
        }
    }
    
    fileprivate func buildCanvasForRenderCache(images: [UIImage], frameView: FrameView, cropRects: [CGRect]) -> CIImage {
        var imageCrops = cropRects.enumerated().map { (index, rect) -> CGRect in
            let img = images[index]
            return rect.applying(CGAffineTransform(scaleX: img.size.width, y: img.size.height))
        }
        var croppedImages = images.map{CIImage(image: $0)!}.enumerated().map({(index, img) in img.cropped(to: imageCrops[index])})
        return CIImage.concateImages(images: croppedImages)
    }
    
    func renderCache(frameView: FrameView, imageEntities: [Image], cropRects: [CGRect], complete:  @escaping (UIImage) -> Void) {
        Image.resolve(images: imageEntities, completion: { originalImages in
            let filteredOriginalImages = originalImages as! [UIImage]
            let frameRects = frameView.frameRects
            var canvas = self.buildCanvasForRenderCache(images: filteredOriginalImages, frameView: frameView, cropRects: cropRects)
            
            UIGraphicsBeginImageContext(canvas.extent.size)
            
            let imageScale = canvas.extent.width/(self.frame.size.width*UIScreen.main.scale)
            let viewScale = canvas.extent.width/self.frame.size.width
            let fromRawToConcateScale = canvas.extent.width/filteredOriginalImages.min(by: {$0.size.width < $1.size.width})!.size.width

            let renderer = PreviewRenderer(imageScale: imageScale)
            
            let pixelImage = self.applyPixel(image: canvas, pixelScale: self.selectedPixelScale)
            canvas = self.pixellate(ciImage: canvas, forExport: true, transformCrop: CGAffineTransform(scaleX: canvas.extent.width/self.frame.size.width, y: canvas.extent.width/self.frame.size.width), pixellateImage: pixelImage)

            if let sign = self.sign {
                let labelView = UILabel()
                labelView.textColor = UIColor.white
                labelView.font = UIFont.systemFont(ofSize: viewScale * self.signFontSize)
                labelView.text = sign
                labelView.sizeToFit()
                let labelImage = labelView.renderToCIImage()
                self.drawSign(canvas: &canvas, signImage: labelImage, viewScale: viewScale, forExport: true)
            }
            
            let canvasImage = canvas.convertToUIImage()
            canvasImage.draw(at: CGPoint.zero)
            
            if frameView.frameType != .none {
                let frameScale = canvas.extent.width/frameView.frame.width
                renderer.drawFrameRects(rect: canvas.extent, frameType: frameView.frameType, frameRects: frameRects.map{ $0.applying(CGAffineTransform(scaleX: fromRawToConcateScale, y: fromRawToConcateScale))}, scale: frameScale)
            }
            
            let cache = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            
            complete(cache)
        })
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
    
    func refreshPixelImage() {
        let selectedPixelImage = pixellateImages[selectedPixelScale]!
        pixellateImage = pixellate(ciImage: image, forExport: false, pixellateImage: selectedPixelImage)
    }
    
    func updatePixellate(uiRect: CGRect) {
        if crops.count == 0 {
            addPixellate(uiRect: uiRect)
        }
        
        crops[crops.count - 1].rect = convertUIRectToCIRect(uiRect: uiRect)
        crops[crops.count - 1].rendered = false
        
        refreshPixelImage()
    }
    
    func rerenderCrops() {
        previousImage = image
        for index in 0..<crops.count {
            crops[index].rendered = false
        }
        
        refreshPixelImage()
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
