//
//  ComposeCell.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/3.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import Photos

struct ScalableConstant {
    var scale = CGFloat(1)
    var constant = CGFloat(0)
    
    mutating func addConstant(delta: CGFloat) -> CGFloat {
        constant = constant + delta
        return finalConstant()
    }
    
    mutating func multiplyScale(_ scale: CGFloat) -> CGFloat {
        self.scale = self.scale * scale
        return finalConstant()
    }
    
    func finalConstant() -> CGFloat {
        return scale*constant
    }
    
    func finalConstant(byScale: CGFloat) -> CGFloat {
        return byScale*constant
    }
}

extension UIScreen {
    
    var pixelSize: CGSize {
        return self.bounds.size.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
    
    var pixelBounds: CGRect {
        return self.bounds.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

class ComposeCell: UIView, EditDelegator {
    
    @IBOutlet weak var image: UIImageView!
    
    var imageEntity: Image!
    
    var index: Int!
    var editState = EditState.inactive(fromDirections: nil)
    weak var onCellScrollDelegator: OnCellScroll?
    
    var originFrame: CGRect?
    
    var imageManager = PHCachingImageManager.default() as! PHCachingImageManager
    var loadingTag = Int32(0)

    override func awakeFromNib() {
    }
    
    func editStateChanged(state: EditState) {
        editState = state
    }
    
    enum Position: Int {
        case above = -1, below = 1
    }
    
    //        above: -1
    //        below: 1
    static func getPositionToSeperator(editState: EditState, cellIndex: Int) -> Position? {
        if case .editing(_, let seperatorIndex) = editState {
            if editState.maybeVertical(), let seperatorIndex = seperatorIndex {
                if cellIndex - seperatorIndex == 1 || cellIndex - seperatorIndex == -1 {
                    return Position.above
                } else if cellIndex - seperatorIndex == 0 {
                    return Position.below
                }
            }
        }
        
        return nil
    }
    
    func scrollY(_ position: ComposeCell.Position, _ translateY: CGFloat) {
        let shrink = CGFloat(position.rawValue) * translateY < 0
        
        let topConstraint = self.constraints.filter {$0.identifier == "top"}.first!
        let bottomConstraint = self.constraints.filter {$0.identifier == "bottom"}.first!
        let absTranslateY: CGFloat = abs(translateY)
        
        let deltaTranslateY = (shrink ? -1 : 1) * absTranslateY
        if case .above = position {
            let newContraint: CGFloat = bottomConstraint.constant + deltaTranslateY
            if newContraint < 0 {
                if !(shrink && frame.height - absTranslateY < 60) {
                    bottomConstraint.constant = newContraint
                    onCellScrollDelegator?.onCellScroll(translate: Float(translateY), cellIndex: index, position: position)
                }
            }
        } else if case .below = position {
            let newContraint: CGFloat = topConstraint.constant - deltaTranslateY
            if newContraint > 0 {
                if !(shrink && frame.height - absTranslateY < 10) {
                    topConstraint.constant = newContraint
                    onCellScrollDelegator?.onCellScroll(translate: Float(translateY), cellIndex: index, position: position)
                }
            }
        }
    }
    
    func convertPercentageToPT(percentage: CGFloat) -> CGFloat {
        return image.bounds.height * percentage
    }
    
    func scrollDown(percentage: CGFloat) {
        scrollY(.above, convertPercentageToPT(percentage: percentage))
    }
    
    func scrollUp(percentage: CGFloat) {
        scrollY(.below, convertPercentageToPT(percentage: percentage))
    }

    func scrollVertical(_ sender: UIPanGestureRecognizer) {
        
        guard case .editing = editState else {
            return
        }
        
        let translate = sender.translation(in: self)
        
        guard let position = ComposeCell.getPositionToSeperator(editState: editState, cellIndex: index) else {
            return
        }
        
        let translateY = translate.y
        
        scrollY(position, translateY)

        sender.setTranslation(CGPoint.zero, in: image)
    }
    
    func setup(image: Image) {
        setupPlaceholder()
        
        self.imageEntity = image
        
        if let constraint = (self.constraints.filter { $0.identifier == "ratio" }.first) {
            self.removeConstraint(constraint)
        }
        
        let ratioConstraint: NSLayoutConstraint = NSLayoutConstraint(item: self.image, attribute: .width, relatedBy: .equal, toItem: self.image, attribute: .height, multiplier: CGFloat(image.assetSize.width)/CGFloat(image.assetSize.height), constant: 0)
        ratioConstraint.identifier = "ratio"
        self.addConstraint(ratioConstraint)
    }
    
    fileprivate func setImage(uiImage: UIImage) {
        image.image = uiImage
    }
    
    func getCropRectForExport(wrapperBounds: CGRect) -> CGRect {
        var inter = wrapperBounds.intersection(self.bounds)
        inter = inter.applying(CGAffineTransform(scaleX: 1.0/self.image.frame.width, y: 1.0/self.image.frame.height))
        inter.origin.y = 1 - inter.origin.y - inter.height
        return inter
    }
    
    func getIntersection(wrapperBounds: CGRect) -> CGRect {
        var inter: CGRect = self.image.convert(bounds, from: self).intersection(self.image.convert(wrapperBounds, from: self))
        inter = inter.applying(CGAffineTransform(scaleX: 1.0/self.image.frame.width, y: 1.0/self.image.frame.height))
        inter.origin.y = 1 - inter.origin.y - inter.height
        return inter
    }
        
    func exportSnapshot(callback: @escaping (CIImage) -> Void, wrapperBounds: CGRect, targetWidth: CGFloat) {
        var inter = self.getIntersection(wrapperBounds: wrapperBounds)
        self.imageEntity.resolve(completion: { (img) in
            if let img = img {
                inter = inter.applying(CGAffineTransform(scaleX: img.size.width, y: img.size.height))
                var imageCache = CIImage(image: img)!
                imageCache = imageCache.cropped(to: inter)
                callback(imageCache)
            } else {
                print("parse \(String(describing: img)) error")
            }
        }, resizeMode: .exact, isSynchronize: false)
    }
    
    func exportSnapshot(wrapperBounds: CGRect) -> UIImage {
        var inter = getIntersection(wrapperBounds: wrapperBounds)

        let img = self.image.image!
        
        var imageCache = CIImage(image: img)!
        inter = inter.applying(CGAffineTransform(scaleX: img.size.width, y: img.size.height))
        imageCache = imageCache.cropped(to: inter)
        
        return imageCache.convertToUIImage()
   }
}


extension ComposeCell : RecycleCell {
    
    func cacheImage() {
        print("cache : \(index!)")
        let size = CGSize(width: UIScreen.main.pixelSize.width, height: CGFloat(imageEntity.asset.pixelHeight)/CGFloat(imageEntity.asset.pixelWidth)*UIScreen.main.pixelSize.width)
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        imageManager.startCachingImages(for: [imageEntity.asset], targetSize: size, contentMode: .aspectFill, options: options)
    }
    
    func purgeImageCache() {
        print("purge cache : \(index!)")
        let size = CGSize(width: UIScreen.main.pixelSize.width, height: CGFloat(imageEntity.asset.pixelHeight)/CGFloat(imageEntity.asset.pixelWidth)*UIScreen.main.pixelSize.width)
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        imageManager.stopCachingImages(for: [imageEntity.asset], targetSize: size, contentMode: .aspectFill, options: options)
    }
    
    
    func loadImage() {
        guard loadingTag == Int32(0) && image.image == nil else {
            return
        }        
        showPlaceholder()
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact
        let width = UIScreen.main.pixelSize.width
        loadingTag = imageEntity.resolve(completion: { (uiImage) in
            self.setImage(uiImage: uiImage!)
            self.showContentView()
        }, targetWidth: width, resizeMode: .fast, contentMode: .aspectFill, cache: true)
    }
    
    func unloadImage() {
        image.image = nil
        loadingTag = Int32(0)
    }
    
    func getFrame() -> CGRect {
        return frame
    }
}


extension ComposeCell : LoadingPlaceholder {
    func contentViewVisible(_ show: Bool) {
        image.isHidden = !show
    }
}
