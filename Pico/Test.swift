//
//  Test.swift
//  Pico
//
//  Created by Frank Cheng on 2018/8/24.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import Vision

class Test {
    
//    func run() {
//        let movieScreenshots = ["movie_IMG_3942","movie_IMG_3945","movie_IMG_3947", "movie_IMG_3950", "IMG_3955"].map{UIImage(named: $0)!}
//        movieScreenshots.forEach {image in
//            Image.detectType(image: image, complete: { (type) in
//                print(type)
//            })
//        }
//    }
    
    func run() {
        var upImage = UIImage(named: "upImage")!.cgImage!
        var downImage = UIImage(named: "downImage")!.cgImage!
        
        
//        downImage = (downImage.cropping(to: CGRect(origin: CGPoint(x: 0, y:400), size: CGSize(width: downImage.width, height: 469))))!
        
        
        let request = VNTranslationalImageRegistrationRequest(targetedCGImage: downImage, completionHandler: { (req, error) in
            if let first = req.results?.first, let obs = first as? VNImageTranslationAlignmentObservation {
                print("transform \(obs.alignmentTransform) confidence: \(obs.confidence)")
            }
        })
        
        request.regionOfInterest = CGRect(origin: CGPoint(x: 0, y: 0.39), size: CGSize(width: 1, height: 0.31))
        
        try! VNImageRequestHandler(cgImage: upImage, options: [:]).perform([request])
    }
//
//    func runA() {
//        var upImage = UIImage(named: "IMG_3978")!.cgImage!
//        var downImage = UIImage(named: "IMG_3979")!.cgImage!
////        downImage = downImage.cropping(to: CGRect(origin: CGPoint(x: 0, y: 822), size: CGSize(width: downImage.width, height: downImage.height - 822)))!
////        upImage = upImage.cropping(to: CGRect(origin: CGPoint.zero, size: CGSize(width: upImage.width, height: upImage.height - 250)))!
//
////        let upImage = UIImage(named: "IMG_3960")!.cgImage!
////        let downImage = UIImage(named: "IMG_3961")!.cgImage!
//
////        let upImage = UIImage(named: "IMG_3961_1")!.cgImage!
////        let downImage = UIImage(named: "IMG_3960")!.cgImage!
//
//        var normHeight = CGFloat(1)
//        let height = normHeight*CGFloat(upImage.height)
//        let leftHeight = CGFloat(upImage.height) - CGFloat(height)
//        print("height:\(height)\t left height: \(leftHeight)")
//
//        let request = VNTranslationalImageRegistrationRequest(targetedCGImage: downImage, completionHandler: { (req, error) in
//            // ty should be the gap from top to middle of up image
//            // ty should be negative
//            if let first = req.results?.first, let obs = first as? VNImageTranslationAlignmentObservation {
//                if obs.alignmentTransform.ty < 0 {
//                    let upShift = leftHeight
//                    let downShift = CGFloat(upImage.height) - (abs(obs.alignmentTransform.ty) + leftHeight)
////                    print("upShift: \(upShift) downShift: \(downShift)")
//                }
//                print("transform \(obs.alignmentTransform)")
//            }
//        })
//
////        request.regionOfInterest = CGRect(x: 0, y: 0, width:1, height:normHeight)
//        request.regionOfInterest = CGRect(x: 0, y: 0, width:1, height:normHeight)
//
//        try! VNImageRequestHandler(cgImage: upImage, options: [:]).perform([request])
//    }
    
    
    func runA() {
//        var h = 1817
//
//
//        var upImage = UIImage(named: "IMG_3960")!.cgImage!
//        var upRect = CGRect(origin: CGPoint(x: 0, y: 1300), size: CGSize(width: upImage.width, height: 1522 - 1300))
//        upImage = upImage.cropping(to: upRect)!
//
//        var downImage = UIImage(named: "IMG_3961")!.cgImage!
//        var downRect = CGRect(origin: CGPoint(x: 0, y: downImage.height - 1879), size: CGSize(width: downImage.width, height: 1000))
//        downImage = downImage.cropping(to: downRect)!
        
        let upImage = UIImage(named: "upImage")!.cgImage!
        let downImage = UIImage(named: "Slice")!.cgImage!
        
        var normHeight = CGFloat(1)
        let height = normHeight*CGFloat(upImage.height)
        let leftHeight = CGFloat(upImage.height) - CGFloat(height)
        
        let request = VNTranslationalImageRegistrationRequest(targetedCGImage: downImage, completionHandler: { (req, error) in
            // ty should be the gap from top to middle of up image
            // ty should be negative
            if let first = req.results?.first, let obs = first as? VNImageTranslationAlignmentObservation {
                if obs.alignmentTransform.ty < 0 {
                    let upShift = leftHeight
                    let downShift = CGFloat(upImage.height) - (abs(obs.alignmentTransform.ty) + leftHeight)
                    print("upShift: \(upShift) downShift: \(downShift)")
                }
                print("transform \(obs.alignmentTransform) confidence: \(obs.confidence)")
            }
        })
        
        //        request.regionOfInterest = CGRect(x: 0, y: 0, width:1, height:normHeight)
        request.regionOfInterest = CGRect(x: 0, y: 0, width:1, height:normHeight)
        
        try! VNSequenceRequestHandler().perform([request], on: upImage)
//        try! VNImageRequestHandler(cgImage: upImage, options: [:]).perform([request])
    }
}
