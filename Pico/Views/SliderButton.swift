//
//  SliderButton.swift
//  Pico
//
//  Created by Frank Cheng on 2018/9/28.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

enum SliderDirection : String, CaseIterable {
    case top = "top"
    case middle = "middle"
    case bottom = "bottom"
    
    case left = "left"
    case right = "right"
    
    static func parse(direction: String) -> SliderDirection {
        return SliderDirection.allCases.first {$0.rawValue == direction}!
    }
    
    func isVertical() -> Bool {
        return [SliderDirection.top, .middle, .bottom].contains(self)
    }

    var buttonSize: CGSize {
        if self.isVertical() {
            return CGSize(width: 50, height: 20)
        } else {
            return CGSize(width: 20, height: 50)
        }
    }
}

class SliderIconView : UIImageView {
    
    var widthConstraint: NSLayoutConstraint!
    var initWidth = CGFloat(12)
    
    var scale: CGFloat = 1.0 {
        didSet {
            widthConstraint.constant = initWidth * scale
        }
    }
    
    enum Icons : String {
        case normal = "seperator-edit"
        case selected = "check-solid"
        
        var instance : UIImage {
            return UIImage(named: self.rawValue)!
        }
    }
    
    init() {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        image = Icons.normal.instance
        widthConstraint = widthAnchor.constraint(equalToConstant: initWidth)
        widthConstraint.isActive = true
        contentMode = .scaleAspectFit
        heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class SliderButton : UIButton {
    
    var widthConstraint: NSLayoutConstraint!
    var iconView: SliderIconView!
    var direction: SliderDirection!
    
    var calculatedSize: CGSize {
        let width = scale * direction.buttonSize.width
        let height = width * direction.buttonSize.height/direction.buttonSize.width
        return CGSize(width: width, height: height)
    }
    
    func setup(direction: SliderDirection) {
        self.direction = direction
        translatesAutoresizingMaskIntoConstraints = false
        
        updateCorner()
        
        iconView = SliderIconView()
        addSubview(iconView)
        iconView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        iconView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        widthConstraint = widthAnchor.constraint(equalToConstant: direction.buttonSize.width)
        widthConstraint.isActive = true
        widthAnchor.constraint(equalTo: heightAnchor, multiplier: direction.buttonSize.width/direction.buttonSize.height, constant: 1).isActive = true
        
        addTarget(self, action: #selector(onStateChanged(event:)), for: .allEvents)
    }
    
    @objc func onStateChanged(event: Event) {
        if event.contains(.touchUpInside) {
            if state.contains(.selected) {
                iconView.image = SliderIconView.Icons.selected.instance
            } else {
                iconView.image = SliderIconView.Icons.normal.instance
            }
        }
    }
    
    let originSize = CGSize(width: 20, height: 50)
    
    var scale: CGFloat = 1.0 {
        didSet {
        }
    }
    
    func setScale(_ scale: CGFloat) {
        self.scale = scale
        print("new width: \(scale * direction.buttonSize.width)")
        widthConstraint.constant = scale * direction.buttonSize.width
        iconView.scale = scale
        updateCorner()
    }
    
    override var bounds: CGRect {
        didSet {
            updateCorner()
        }
    }
    
    fileprivate func updateCorner() {
        switch direction! {
        case .left:
            roundCorners([.topRight, .bottomRight], radius: calculatedSize.height/2)
        case .right:
            roundCorners([.topLeft, .bottomLeft], radius: calculatedSize.height/2)
        case .top:
            roundCorners([.bottomLeft, .bottomRight], radius: calculatedSize.height)
        case .middle:
            roundCorners([.bottomLeft, .bottomRight, .topLeft, .topRight], radius: calculatedSize.height/2)
        case .bottom:
            roundCorners([.topLeft, .topRight], radius: calculatedSize.height)
        }
    }
    
    fileprivate var scaledSize : CGSize {
        return originSize.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
    
    func setIcon(_ icon: UIImage) {
        iconView.image = icon
    }
}

