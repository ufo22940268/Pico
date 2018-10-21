//
//  ZoomScrollView.swift
//  Pico
//
//  Created by Frank Cheng on 2018/10/19.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class ZoomScrollView: UIScrollView {
    
    var maxZoomScale:CGFloat = 2.0
    
    override func awakeFromNib() {
        maximumZoomScale = maxZoomScale
        minimumZoomScale = 0.4
        
        let tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap(_:)))
        tapGestureRecognizer.cancelsTouchesInView = false
        tapGestureRecognizer.isEnabled = true
        tapGestureRecognizer.numberOfTapsRequired = 2
        tapGestureRecognizer.delaysTouchesEnded = false
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func onDoubleTap(_ gesture: UITapGestureRecognizer) {
        
        if locationInSeperator(gesture: gesture) {
            return
        }
        
        if zoomScale < 1.0 {
            setZoomScale(1.0, animated: true)
        } else if zoomScale == 1.0 {
            let touchPoint = gesture.location(in: self)
            let size = bounds.size.applying(CGAffineTransform(scaleX: 1.0/maxZoomScale, y: 1.0/maxZoomScale))
            zoom(to: CGRect(origin: touchPoint.applying(CGAffineTransform(translationX: -size.width/2, y: -size.height/2)), size: size), animated: true)
        } else if zoomScale == maxZoomScale {
            setZoomScale(1.0, animated: true)
        }
    }
    
    func locationInSeperator(gesture: UITapGestureRecognizer) -> Bool {
        if let containerWrapper = subviews.first, let container = containerWrapper.subviews.first {
            for seperator in container.subviews where seperator is SliderSelectable {
                if let seperatorSlider = seperator as? SeperatorSlider {
                    if seperatorSlider.button.point(inside: gesture.location(in: seperatorSlider.button), with: nil) {
                        return true
                    }
                } else if let sideSlider = seperator as? SideSlider {
                    if sideSlider.button.point(inside: gesture.location(in: sideSlider.button), with: nil) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
}
