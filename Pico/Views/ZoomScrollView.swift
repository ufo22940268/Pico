//
//  ZoomScrollView.swift
//  Pico
//
//  Created by Frank Cheng on 2018/10/19.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit


protocol ZoomScrollViewDelegate: class {
    func onChangeTo(scale: CGFloat)
}

class ZoomScrollView: UIScrollView {
    
    var maxZoomScale:CGFloat = 2.0    
    
    weak var zoomDelegate: ZoomScrollViewDelegate?
    
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
        
        
        self.layoutIfNeeded()
        UIView.animate(withDuration: 0.15) {
            var newScale:CGFloat
            if self.zoomScale < 1.0 {
                self.setZoomScale(1.0, animated: false)
                newScale = 1.0
            } else if self.zoomScale >= 1.0 && self.zoomScale < self.maxZoomScale {
                let touchPoint = gesture.location(in: self)
                let size = self.bounds.size.applying(CGAffineTransform(scaleX: 1.0/self.maxZoomScale, y: 1.0/self.maxZoomScale))
                self.zoom(to: CGRect(origin: touchPoint.applying(CGAffineTransform(translationX: -size.width/2, y: -size.height/2)), size: size), animated: false)
                newScale = self.maxZoomScale
            } else {
                self.setZoomScale(1.0, animated: false)
                newScale = 1.0
            }

            self.zoomDelegate?.onChangeTo(scale: newScale)
            self.layoutIfNeeded()
        }
    }
    
    
    func locationInSeperator(gesture: UITapGestureRecognizer) -> Bool {
        if let containerWrapper = subviews.first, let container = containerWrapper.subviews.first {
            for seperator in container.subviews where seperator is Slider {
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
