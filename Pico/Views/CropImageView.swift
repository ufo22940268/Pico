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
    
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var imageView: UIImageView!
    
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
            let size = bounds.size
            let crop = cropRect.applying(CGAffineTransform(scaleX: size.width, y: size.height))
            
            let leftPadding = crop.minX
            let topPadding = crop.minY
            let rightPadding = size.width - crop.maxX
            let bottomPadding = size.height - crop.maxY
            
            leadingConstraint.constant = -leftPadding
            topConstraint.constant = -topPadding
            trailingConstraint.constant = -rightPadding
            bottomConstraint.constant = -bottomPadding
        }
    }
}
