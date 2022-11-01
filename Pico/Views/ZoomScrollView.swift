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
    func onZoomTo(destinationRect: CGRect?)

    func onResetZoomScale()
}

extension UIScrollView {
    func zoom(toPoint zoomPoint : CGPoint, scale : CGFloat, animated : Bool) -> CGRect {
        var scale = CGFloat.minimum(scale, maximumZoomScale)
        scale = CGFloat.maximum(scale, self.minimumZoomScale)
        
        var translatedZoomPoint : CGPoint = .zero
        translatedZoomPoint.x = zoomPoint.x + contentOffset.x
        translatedZoomPoint.y = zoomPoint.y + contentOffset.y
        
        let zoomFactor = 1.0 / zoomScale
        
        translatedZoomPoint.x *= zoomFactor
        translatedZoomPoint.y *= zoomFactor
        
        var destinationRect : CGRect = .zero
        destinationRect.size.width = frame.width / scale
        destinationRect.size.height = frame.height / scale
        destinationRect.origin.x = translatedZoomPoint.x - destinationRect.width * 0.5
        destinationRect.origin.y = translatedZoomPoint.y - destinationRect.height * 0.5
        
        if animated {
            UIView.animate(withDuration: 0.55, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.6, options: [.allowUserInteraction], animations: {
                self.zoom(to: destinationRect, animated: false)
            }, completion: {
                completed in
                if let delegate = self.delegate, delegate.responds(to: #selector(UIScrollViewDelegate.scrollViewDidEndZooming(_:with:atScale:))), let view = delegate.viewForZooming?(in: self) {
                    delegate.scrollViewDidEndZooming!(self, with: view, atScale: scale)
                }
            })
        } else {
            zoom(to: destinationRect, animated: false)
        }
        
        return destinationRect
    }
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
        
        var newScale:CGFloat
        
        if self.zoomScale >= 1.0 && self.zoomScale < self.maxZoomScale {
            let touchPoint = gesture.location(in: self)
            newScale = self.maxZoomScale
            
            UIView.animate(withDuration: 0.3) {
                let destinationRect = self.zoom(toPoint: touchPoint, scale: self.maxZoomScale, animated: false)
                self.zoomDelegate?.onZoomTo(destinationRect: destinationRect)
                self.superview!.layoutIfNeeded()
            }
        } else {
            newScale = 1.0
            
            UIView.animate(withDuration: 0.3) {
                self.setZoomScale(newScale, animated: false)
                self.zoomDelegate?.onResetZoomScale()
                self.superview!.layoutIfNeeded()
            }
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
