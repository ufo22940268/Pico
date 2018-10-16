//
//  GalleryDetailCell.swift
//  Pico
//
//  Created by Frank Cheng on 2018/10/16.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class GalleryDetailCell: UICollectionViewCell {
    
    var imageView: UIImageView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func awakeFromNib() {
        imageView = UIImageView(frame: CGRect.zero)
        addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
}
