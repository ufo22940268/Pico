//
//  CropImageView.swift
//  Pico
//
//  Created by Frank Cheng on 2018/10/8.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class CropImageView : UIView {
    
    var trailingConstraint: NSLayoutConstraint!
    var bottomConstraint: NSLayoutConstraint!
    var leadingConstraint: NSLayoutConstraint!
    var topConstraint: NSLayoutConstraint!

    var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        
        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleToFill
        addSubview(imageView)
        
        trailingConstraint = safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: imageView.trailingAnchor)
        trailingConstraint.isActive = true
        bottomConstraint = safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
        bottomConstraint.isActive = true
        topConstraint = imageView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor)
        topConstraint.isActive = true
        leadingConstraint = imageView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor)
        leadingConstraint.isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var image: UIImage? {
        get {
            return imageView.image
        }
        
        set(newImage) {
            imageView.image = newImage
        }
    }
    
    var cropRect: CGRect! {
        didSet {
            let parentViewSize = superview!.bounds.size
            let size = CGSize(width: parentViewSize.width/cropRect.width, height: parentViewSize.height/cropRect.height)
            let crop = cropRect.applying(CGAffineTransform(scaleX: size.width, y: size.height))
            
            let leftPadding = crop.minX
            let topPadding = crop.minY
            let rightPadding = size.width - crop.maxX
            let bottomPadding = size.height - crop.maxY
            
            leadingConstraint.constant = -leftPadding
            topConstraint.constant = -bottomPadding
            trailingConstraint.constant = -rightPadding
            bottomConstraint.constant = -topPadding
        }
    }
}
