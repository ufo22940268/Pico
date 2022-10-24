//
//  SliderProtocal.swift
//  Pico
//
//  Created by Frank Cheng on 2018/8/7.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

protocol Slider {
    
    var placeholder: SliderPlaceholder! {
        get set
    }
    
    func updateSelectState(_ newSelectState: Bool) -> Void

}

extension Slider where Self: UIView {
    
    func syncFrame() {
        if placeholder != nil, let frameInRootView =  placeholder.frameInRootView {
            self.frame = frameInRootView
        }
    }
}
