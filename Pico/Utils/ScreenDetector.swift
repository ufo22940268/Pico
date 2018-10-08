//
//  ScreenDetector.swift
//  Pico
//
//  Created by Frank Cheng on 2018/10/8.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class ScreenDetector {
    static let internalSizes:[[String:CGSize]] = [
        ["nativeSize": CGSize(width:1125, height:2436), "uiSize": CGSize(width:375, height:812)],
        ["nativeSize": CGSize(width:1080, height:1920), "uiSize": CGSize(width:414, height:736)],
        ["nativeSize": CGSize(width:750, height:1334), "uiSize": CGSize(width:375, height:667)],
        ["nativeSize": CGSize(width:1080, height:1920), "uiSize": CGSize(width:414, height:736)],
        ["nativeSize": CGSize(width:1080, height:1920), "uiSize": CGSize(width:375, height:667)],
        ["nativeSize": CGSize(width:1080, height:1920), "uiSize": CGSize(width:375, height:667)],
        ["nativeSize": CGSize(width:750, height:1334), "uiSize": CGSize(width:375, height:667)],
        ["nativeSize": CGSize(width:750, height:1334), "uiSize": CGSize(width:375, height:667)],
        ["nativeSize": CGSize(width:750, height:1334), "uiSize": CGSize(width:375, height:667)],
        ["nativeSize": CGSize(width:640, height:1136), "uiSize": CGSize(width:320, height:568)]
    ]
    
    static var allScreenshotSizes:[CGSize] {
        var allSizes = Array(internalSizes.map {[$0["nativeSize"]!, $0["uiSize"]!]}.joined())
        allSizes.append(UIScreen.main.bounds.size)
        allSizes.append(UIScreen.main.pixelSize)
        return allSizes
    }
    
    static func isScreenshot(size: CGSize) -> Bool {
        return allScreenshotSizes.contains(size)
    }
}
