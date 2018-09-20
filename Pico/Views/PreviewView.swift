//
//  PreviewView.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/17.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit
import GLKit

struct CropArea: Hashable {
    var hashValue: Int {
        return seq
    }
    
    static func == (lhs: CropArea, rhs: CropArea) -> Bool {
        return lhs.seq == rhs.seq
    }
    
    init(rect: CGRect, seq: Int) {
        self.rect = rect
        self.seq = seq
    }
    
    var rect: CGRect!
    var seq: Int!
    var closed: Bool = false
    var cropRect: CGRect?
}

enum PreviewPixellateScale: Int {
    case small = 7
    case middle = 14
    case large = 21
}

struct PreviewConstants {
    static let frameWidth = CGFloat(8)
    static let signFontSize = CGFloat(20)
}

class PreviewView: UIStackView {

    var previousImage: CIImage!
    var uiImages: [UIImage]!
    var imageEntities: [Image] = [Image]()
    
    var sign: String? {
        willSet(newSign) {
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
    var signImage: CIImage?
    var cells: [PreviewCell]!
    
    var image: CIImage! {
        willSet(newImage) {
            previousImage = newImage
        }
    }
    
    var selection: CGRect?
    var ciContext: CIContext!
    var areas: [CropArea] = [CropArea]()
    var labelView: UILabel!
    var pixellateImages = [PreviewPixellateScale: CIImage]()
    
    var pixellateImage: CIImage?
    var signFontSize = CGFloat(20)
    
    var frameType: PreviewFrameType = .none
    
    override func awakeFromNib() {
        
        labelView = UILabel()
        labelView.textColor = UIColor.white
        labelView.font = UIFont.systemFont(ofSize: signFontSize*UIScreen.main.scale)
        
        axis = .vertical
        directionalLayoutMargins = NSDirectionalEdgeInsets.zero
        
        ciContext = CIContext(eaglContext: eaglContext)
        
    }
    
    func convertUIRectToCIRect(uiRect: CGRect) -> CGRect {
        return uiRect.convertLTCToLBC(frameHeight: 1)
    }
    
   
    fileprivate func scalaToFill(image: CIImage, width: CGFloat) -> CIImage {
        let scale = width / image.extent.width
        return image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }
    
    let eaglContext = EAGLContext(api: .openGLES3)!
    
    func addCell(with image: Image) -> PreviewCell {
        let cell = PreviewCell(image: image, ciContext: ciContext, eaglContext: eaglContext)
        addArrangedSubview(cell)
        return cell
    }

    func setupCells(images: [Image], fillContainer: Bool = true) -> Void {
        cells = imageEntities.map {addCell(with: $0)}
    }
    
    func applyPixel(image: CIImage, pixelScale: PreviewPixellateScale) -> CIImage {
        return image.applyingFilter("CIPixellate", parameters: ["inputScale": pixelScale.rawValue])
    }
    
    func preparePixellateImages(_ image: CIImage) {
        for scale in [PreviewPixellateScale.small, .middle, .large] {
            pixellateImages[scale] = applyPixel(image: image, pixelScale: scale)
        }
    }
    
    fileprivate func cropImagesForExport(images: [UIImage], cropRects: [CGRect]) -> [CIImage] {
        var imageCrops = cropRects.enumerated().map { (index, rect) -> CGRect in
            let img = images[index]
            return rect.applying(CGAffineTransform(scaleX: img.size.width, y: img.size.height))
        }
        let croppedImages = images.map{CIImage(image: $0)!}.enumerated().map({(index, img) in img.cropped(to: imageCrops[index]).transformed(by: CGAffineTransform(translationX: 0, y: -imageCrops[index].minY))})
        return croppedImages
    }
    
    func renderImageForExport(imageEntities: [Image], cropRects: [CGRect], complete:  @escaping (UIImage) -> Void) {
        Image.resolve(images: imageEntities, completion: { originalImages in
            let filteredOriginalImages = originalImages as! [UIImage]
            
            let croppedImages = self.cropImagesForExport(images: filteredOriginalImages, cropRects: cropRects)
            var finalImages = [CIImage]()
            for (index, croppedImage) in croppedImages.enumerated() {
                let cell = self.cells[ index]
                finalImages.append(PreviewCellDecorator(image: croppedImage, cell: cell).composeImageForExport())
            }
            
            finalImages = CIImage.resizeToSameWidth(images: finalImages)
            finalImages = PreviewFrameDecorator(images: finalImages, frameType: self.frameType).addFrames()
            
            let canvas = CIImage.concateImages(images: finalImages)
            
            let uiCanvas = canvas.convertToUIImage()
            
            complete(uiCanvas)
        })
    }
    
    func loadImages(scrollView: UIScrollView) {
        let visibleRect = convert(scrollView.bounds.intersection(self.frame), from: scrollView)
        let visibleCells = cells.filter {$0.frame.intersects(visibleRect)}
        
        let loadCells = visibleCells
        loadCells.forEach {$0.loadImage()}
        
        
        let unloadCells = cells.filter {!loadCells.contains($0)}
        unloadCells.forEach {$0.unloadImage()}
    }
}

// MARK: - Pixellate functions
extension PreviewView {
    
    fileprivate func findInstersectCells(with rect: CGRect) -> [PreviewCell]? {
        return cells.filter {$0.frame.intersects(rect)}
    }
    
    func undo() {
        if areas.count > 0 {
            let removedCropRect = areas.removeLast()
            syncCropsToCell()
            reloadVisibleCells()
        }
    }
    
    func syncCropsToCell() {
        var dict = [PreviewCell: [CropArea]]()
        for area in areas {
            if let cells = findInstersectCells(with: area.rect.applying(CGAffineTransform(scaleX: bounds.width, y: bounds.height))) {
                for cell in cells {
                    if dict[cell] == nil {
                        dict[cell] = [CropArea]()
                    }
                    
                    dict[cell]?.append(area)
                }
            }
        }
        
        for (cell, areas) in dict {
            var areasWithCropRect = [CropArea: CGRect]()
            for area in areas {
                let intersectRect = area.rect.applying(CGAffineTransform(scaleX: bounds.width, y: bounds.height)).intersection(cell.frame)
                let cropRect = cell.convert(intersectRect, from: self).applying(CGAffineTransform(scaleX: 1/CGFloat(cell.bounds.width), y: 1/CGFloat(cell.bounds.height)))
                areasWithCropRect[area] = cropRect
            }
            cell.sync(with: areasWithCropRect)
        }
        
        for cell in cells where !dict.keys.contains(cell) {
            cell.sync(with: [CropArea:CGRect]())
        }
    }
    
    func reloadVisibleCells() {
        let displayRect = convert(superview!.bounds, from: superview).intersection(bounds)
        findInstersectCells(with: displayRect)?.forEach {
            $0.displayCrop()
            $0.displaySign()
        }
    }
    
    fileprivate func addPixellate(uiRect: CGRect) {
        let ciRect = convertUIRectToCIRect(uiRect: uiRect)
        areas.append(CropArea(rect: ciRect, seq: areas.count))
    }
    
    func updatePixelInCells() {
        for index in 0..<areas.count {
            let viewCrop = areas[index]
            let viewRect: CGRect = viewCrop.rect
            
            let rectInUICoordinate = viewRect.applying(transform.scaledBy(x: bounds.width, y: bounds.height))
            findInstersectCells(with: rectInUICoordinate)?.forEach { cell in
                let intersectionCrop = cell.convert(rectInUICoordinate.intersection(cell.frame), from: self).applying(CGAffineTransform(scaleX: 1/CGFloat(cell.bounds.width), y: 1/CGFloat(cell.bounds.height)))
                cell.updateCrop(with: intersectionCrop, identifier: viewCrop)
            }
        }
    }
    
    func setPixelScale(scale: PreviewPixellateScale) {
        cells.forEach {$0.setPixelScale(scale)}
    }
    
    func updatePixellate(uiRect: CGRect) {
        if areas.count == 0 || areas.last!.closed {
            addPixellate(uiRect: uiRect)
        }
        
        areas[areas.count - 1].rect = uiRect
        
//        updatePixelInCells()
        syncCropsToCell()
        reloadVisibleCells()
    }
    
    func closeLastRectCrop() {
        guard areas.count > 0 else {
            return
        }
        
        areas[areas.count - 1].closed = true
    }
}

// MARK: - Signature
extension PreviewView {

    func setSign(sign: String) {
        cells.last?.setSign(sign)
    }
    
    func clearSign() {
        cells.last?.setSign(nil)
    }
    
    func setAlign(align: PreviewAlignMode) {
        cells.last?.setSignAlign(align)
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
}

extension PreviewView {
    
    func showHorizontalSeperator(_ show: Bool) {
        if show {
            spacing = PreviewConstants.frameWidth
        } else {
            spacing = 0
        }
    }
    
    func showInset(_ show: Bool) {
        let insetWidth = show ? PreviewConstants.frameWidth : 0
        
        layoutMargins = UIEdgeInsets(top: insetWidth, left: insetWidth, bottom: insetWidth, right: insetWidth)
        isLayoutMarginsRelativeArrangement = show
    }
    
    
    func updateFrame(_ mode: PreviewFrameType) {
        UIView.animate(withDuration: 0.3) {
            switch mode {
            case .seperator:
                self.showInset(false)
                self.showHorizontalSeperator(true)
            case .full:
                self.showHorizontalSeperator(true)
                self.showInset(true)
            case .none:
                self.showHorizontalSeperator(false)
                self.showInset(false)
            }
        }
        
        frameType = mode
    }
}
