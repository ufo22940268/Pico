//
//  CIImageExtension.swift
//  Pico
//
//  Created by Frank Cheng on 2018/8/1.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

extension CIImage {
    
    func convertToUIImage() -> UIImage
    {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(self, from: self.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
    
    static func concateImages(images: [CIImage]) -> CIImage {
        let minWidth = images.min { (c1, c2) -> Bool in
            return c1.extent.width < c2.extent.width
        }!.extent.width
        var scaledImages = images.map { img -> CIImage in
            let scale = minWidth/img.extent.width
            return img.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        }
        
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
}
