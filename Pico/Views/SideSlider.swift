//
//  SideSlider.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/27.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

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

class SideSliderButton : UIButton {
    
    @objc var direction: String!
    var initButtonWidth = CGFloat(20)
    var widthConstraint: NSLayoutConstraint!
    var iconView: SliderIconView!
    
    override func awakeFromNib() {
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
        switch direction {
        case "left":
            roundCorners([.topRight, .bottomRight], radius: 30)
        case "right":
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

class SideSlider: UIView, SliderSelectable {
    @objc var direction: String!

    @IBOutlet weak var button: SideSliderButton!
    
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    weak var delegate: EditDelegator?
    var arrow: UIImageView!
    var arrowAnimator: UIViewPropertyAnimator!
    
    override func awakeFromNib() {
        translatesAutoresizingMaskIntoConstraints = false
        
        let uiImage: UIImage? = direction == "left" ? UIImage(named: "angle-double-left-solid") : UIImage(named: "angle-double-right-solid")
        
        arrow = UIImageView(image: uiImage)
        arrow.tintColor = UIColor(named: "Slider")
        addSubview(arrow)
        arrow.isHidden = true
        arrow.translatesAutoresizingMaskIntoConstraints = false
        if direction == "left" {
            arrow.leadingAnchor.constraint(equalTo: button.trailingAnchor, constant: SliderConstants.gap).isActive = true
            arrow.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        } else if direction == "right" {
            arrow.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -SliderConstants.gap).isActive = true
            arrow.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        }
    }
    
    func updateSlider(midPoint: CGPoint, transform: CGAffineTransform) {
        topConstraint.constant = midPoint.y
        button.scale = transform.a
    }
    
    func setupAnimation() {
        let originFrame = arrow.frame
        arrowAnimator = UIViewPropertyAnimator(duration: SliderConstants.animatorDuration, curve: .easeInOut, animations: {[weak self] in
            UIView.setAnimationRepeatCount(100000)
            UIView.setAnimationRepeatAutoreverses(true)
            if self != nil {
                let offsetX = self!.direction == "left" ? -SliderConstants.translate : SliderConstants.translate
                self!.arrow.frame = self!.arrow.frame.offsetBy(dx: offsetX, dy: 0)
            }
        })
        arrowAnimator.addCompletion { (pos) in
            self.arrow.frame = originFrame
        }
    }
    
    @IBAction func onToggle(_ sender: UIButton) {
        let newSelectState = !button.isSelected
        updateSelectState(newSelectState)
    }
    
    func updateSelectState(_ newSelectState: Bool) {
        if !newSelectState {
            delegate?.editStateChanged(state: EditState.inactive(fromDirections: direction))
            button.isSelected = newSelectState
            stopAnimator()
        } else {
            delegate?.editStateChanged(state: EditState.editing(direction: direction, seperatorIndex: nil))
            button.isSelected = newSelectState
            startAnimator()
        }
    }
    
    
    func startAnimator() {
        arrow.isHidden = false
        setupAnimation()
        arrowAnimator.startAnimation()
    }
    
    func stopAnimator() {
        arrow.isHidden = true
        if arrowAnimator != nil {
            arrowAnimator.stopAnimation(false)
            arrowAnimator.finishAnimation(at: .current)
        }
    }
    
    func addEditDelegator(editDelegator: EditDelegator) {
        delegate = editDelegator
    }
}
