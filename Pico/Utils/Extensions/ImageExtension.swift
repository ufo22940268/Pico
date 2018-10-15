//
//  UIImageExtension.swift
//  Pico
//
//  Created by Frank Cheng on 2018/9/7.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    func thumbnail() -> UIImage {
        let imageData = self.pngData()!
        let options = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 600] as CFDictionary
        let source = CGImageSourceCreateWithData(imageData as CFData, nil)!
        let imageReference = CGImageSourceCreateThumbnailAtIndex(source, 0, options)!
        let thumbnail = UIImage(cgImage: imageReference)
        return thumbnail
    }
    
    func cropImage(toRect rect:CGRect) -> UIImage{
        let imageRef:CGImage = self.cgImage!.cropping(to: rect)!
        let cropped:UIImage = UIImage(cgImage:imageRef)
        return cropped
    }
    
    func cropToCGImage(in rect:CGRect) -> CGImage {
        let newRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width - 1, height: rect.height)
        let imageRef:CGImage = self.cgImage!.cropping(to: newRect)!
        return imageRef
    }

}


extension CGImage {
    var size:CGSize {
        return CGSize(width: width, height: height)
    }
}
