//
//  PickImageCell.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/3.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit

class PickImageCell: UICollectionViewCell {

    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var selectedSequence: UIView!
    @IBOutlet weak var sequence: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func select(number: Int) {
        selectedSequence.isHidden = false
        sequence.text = String(number + 1)
    }
    
    func unselect() {
        selectedSequence.isHidden = true
    }
}
