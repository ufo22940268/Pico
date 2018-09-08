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
//        let newSize = CGSize(width: 200, height: 200)
//        let image = UIGraphicsImageRenderer(size: newSize).image { context in
//            self.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
//        }
//        return image
        
        let imageData = UIImagePNGRepresentation(self)!
        let options = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 300] as CFDictionary
        let source = CGImageSourceCreateWithData(imageData as CFData, nil)!
        let imageReference = CGImageSourceCreateThumbnailAtIndex(source, 0, options)!
        let thumbnail = UIImage(cgImage: imageReference)
        return thumbnail
    }
}
