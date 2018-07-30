//
//  UIImageViewExtension.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/16.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

extension UIImageView {
    func setImageAndRatio(uiImage: UIImage) {
        image = uiImage
        let ratio: CGFloat = uiImage.size.width/uiImage.size.height
        addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: self, attribute: .height, multiplier: ratio, constant: 0))
    }
    
    func g_pixellate(rect: CGRect) {
        if let uiImage = self.image {
            let imageFrame = frame
            var pixelRect = rect.applying(CGAffineTransform(scaleX: uiImage.size.width/imageFrame.size.width, y: uiImage.size.height/imageFrame.size.height))
            pixelRect.origin.y = uiImage.size.height - pixelRect.origin.y - pixelRect.size.height
            
            DispatchQueue.global(qos: .background).async {
                let openGLContext = EAGLContext(api: .openGLES3)
                let context = CIContext(eaglContext: openGLContext!)
                let originImage = CIImage(image: uiImage)
                let filter = CIFilter(name: "CIPixellate", withInputParameters: ["inputImage": originImage, "inputScale": 30.0] )
                let result = filter!.outputImage!
//                let pixelateImage = filter!.outputImage!.cropped(to: pixelRect)
//                let result = pixelateImage
//                let backgroundImage = originImage
//                let result = CIFilter(name: "CISourceOverCompositing", withInputParameters: ["inputBackgroundImage": backgroundImage, "inputImage": pixelateImage])!.outputImage!
                let cgImage = context.createCGImage(result, from: result.extent)!
                
                DispatchQueue.main.async {
                    self.image = UIImage(cgImage: cgImage)
                }
            }
        }
    }

    
//    func g_pixellate(rect: CGRect) {
//        if let uiImage = self.image {
//            let imageFrame = frame
//            DispatchQueue.global(qos: .background).async {
//                let pixelRect = rect.applying(CGAffineTransform(scaleX: uiImage.size.width/imageFrame.size.width, y: uiImage.size.height/imageFrame.size.height))
//                let context = CIContext()
//                let originImage = CIImage(image: uiImage)
//                let filter = CIFilter(name: "CIPixellate", withInputParameters: ["inputImage": originImage, "inputScale": 20.0] )
//                let pixelateImage = filter!.outputImage!.applyingFilter("CICrop", parameters: ["inputRectangle": CIVector(cgRect: pixelRect)])
//                let backgroundImage = originImage
//                let result = CIFilter(name: "CISourceOverCompositing", withInputParameters: ["inputBackgroundImage": backgroundImage, "inputImage": pixelateImage])!.outputImage!
//                let cgImage = context.createCGImage(result, from: result.extent)!
//                DispatchQueue.main.sync {
//                    self.image = UIImage(cgImage: cgImage)
//                }
//            }
//        }
//    }
}
