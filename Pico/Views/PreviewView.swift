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
    case small = 20
    case middle = 30
    case large = 40
}

struct PreviewConstants {
    static let frameWidth = CGFloat(8)
    static let signFontSize = CGFloat(20)
}

class PreviewView: UIStackView, RecycleList {
    

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
    
    func getCells() -> [RecycleCell] {
        return cells
    }
    
    var selection: CGRect?
    var areas: [CropArea] = [CropArea]()
    var labelView: UILabel!
    
    var pixellateImage: CIImage?
    var signFontSize = CGFloat(20)
    
    var frameType: PreviewFrameType = .none
    
    override func awakeFromNib() {
        
        labelView = UILabel()
        labelView.textColor = UIColor.white
        labelView.font = UIFont.systemFont(ofSize: signFontSize*UIScreen.main.scale)
        
        axis = .vertical
        directionalLayoutMargins = NSDirectionalEdgeInsets.zero
    }
    
    func convertUIRectToCIRect(uiRect: CGRect) -> CGRect {
        return uiRect.convertLTCToLBC(frameHeight: 1)
    }
    
   
    fileprivate func scalaToFill(image: CIImage, width: CGFloat) -> CIImage {
        let scale = width / image.extent.width
        return image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }
    
    func addCell(with image: Image, hasCrop crop: CGRect) -> PreviewCell {
        let cell = PreviewCell(image: image, imageCrop: crop)
        addArrangedSubview(cell)
        return cell
    }

    func setupCells(images: [Image], crops: [CGRect], fillContainer: Bool = true) -> Void {
        cells = imageEntities.enumerated().map { (index, image) in
            addCell(with: image, hasCrop: crops[index])
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
    
    fileprivate func cropImageForExport(image: CIImage, cropRect: CGRect) -> CIImage {
        let imageCrop = cropRect.applying(CGAffineTransform(scaleX: image.extent.width, y: image.extent.height))
        
        return image.cropped(to: imageCrop)
            .resetOffset()
//            .transformed(by: CGAffineTransform(translationX: 0, y: -imageCrop.minY))
    }
    
    func renderImageForExport(imageEntities: [Image], cropRects: [CGRect], complete:  @escaping (UIImage) -> Void) {
        let minWidth = cropRects.enumerated().map { offset, crop in
            return crop.width * CGFloat(imageEntities[offset].asset.pixelWidth)
        }.min()!
        var canvas: CIImage? = nil
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "com.bettycc.pico.preview.export")
        queue.async {
            imageEntities.enumerated().forEach { offset, entity in
                group.enter()
                self.renderSingleCellForExport(entity: entity, minWidth: minWidth, crop: cropRects[offset], offset: offset, complete: { (ciImage) in
                    autoreleasepool {
                        if canvas == nil {
                            canvas = ciImage
                        } else {
                            canvas = CIImage.concateImages(images: [canvas!, ciImage], needScale: false)
                        }
                    }
                    group.leave()
                })
                group.wait()
            }
            
            group.notify(queue: .global()) {
                let uiCanvas = canvas!.convertToUIImage()
                complete(uiCanvas)
            }
        }
        
    }
    
    func renderSingleCellForExport(entity: Image, minWidth: CGFloat, crop: CGRect, offset: Int, complete: @escaping (CIImage) -> Void) {
        let _ = entity.resolve(completion: { (uiImage) in
            var ciImage = CIImage(image: uiImage!)!
            ciImage = self.cropImageForExport(image: ciImage, cropRect: crop).resizeTo(width: minWidth)
            ciImage = PreviewCellDecorator(image: ciImage, cell: self.cells[offset]).composeImageForExport()
            let frameDecorator = PreviewFrameDecorator(image: ciImage, frameType: self.frameType)
            if offset == 0 {
                ciImage = frameDecorator.renderTopFrame()
            } else {
                ciImage = frameDecorator.renderNormalFrame()
            }
            complete(ciImage)
        })
    }
}

// MARK: - Pixellate functions
extension PreviewView {
    
    func undo() {
        if areas.count > 0 {
            _ = areas.removeLast()
            syncCropsToCell()
            reloadVisibleCells()
        }
    }
    
    func findIntersectCellsAndConvert(with rect: CGRect) -> [PreviewCell]? {
        return findIntersectCells(with:rect).map {$0 as! PreviewCell}
    }
    
    func syncCropsToCell() {
        var dict = [PreviewCell: [CropArea]]()
        for area in areas {
            if let cells = findIntersectCellsAndConvert(with: area.rect.applying(CGAffineTransform(scaleX: bounds.width, y: bounds.height))) {
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
        findIntersectCellsAndConvert(with: displayRect)?.forEach {
            $0.updatePixelRects()
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
            findIntersectCellsAndConvert(with: rectInUICoordinate)?.forEach { cell in
                let intersectionCrop = cell.convert(rectInUICoordinate.intersection(cell.frame), from: self).applying(CGAffineTransform(scaleX: 1/CGFloat(cell.bounds.width), y: 1/CGFloat(cell.bounds.height)))
                cell.updatePixelCrop(with: intersectionCrop, identifier: viewCrop)
                cell.updatePixelRects()
            }
        }
    }
    
    func setPixelScale(scale: PreviewPixellateScale) {
        cells.forEach {cell in
            cell.setPixelScale(scale)
            cell.updatePixelImageInPixelView()
        }
    }
    
    func updatePixellate(uiRect: CGRect) {
        if areas.count == 0 || areas.last!.closed {
            addPixellate(uiRect: uiRect)
        }
        
        areas[areas.count - 1].rect = uiRect
        
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
