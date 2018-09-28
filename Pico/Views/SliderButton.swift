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
    
    var initButtonWidth = CGFloat(20)
    var widthConstraint: NSLayoutConstraint!
    var iconView: SliderIconView!
    var direction: SliderDirection!
    
    func setup(direction: SliderDirection) {
        self.direction = direction
        translatesAutoresizingMaskIntoConstraints = false
        
        updateCorner()
        
        iconView = SliderIconView()
        addSubview(iconView)
        iconView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        iconView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        widthConstraint = widthAnchor.constraint(equalToConstant: initButtonWidth)
        widthConstraint.isActive = true
        widthAnchor.constraint(equalTo: heightAnchor, multiplier: CGFloat(20)/CGFloat(50), constant: 1).isActive = true
        
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
            widthConstraint.constant = scale * initButtonWidth
            iconView.scale = scale
        }
    }
    
    override var bounds: CGRect {
        didSet {
            updateCorner()
        }
    }
    
    fileprivate func updateCorner() {
        switch direction! {
        case .left:
            roundCorners([.topRight, .bottomRight], radius: 30)
        case .right:
            roundCorners([.topLeft, .bottomLeft], radius: SliderConstants.buttonHeight/2)
        default:
            break
        }
    }
    
    fileprivate var scaledSize : CGSize {
        return originSize.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
    
    func setIcon(_ icon: UIImage) {
        iconView.image = icon
    }
}

