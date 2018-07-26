//
//  AlbumCell.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/12.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit

class AlbumCell: UITableViewCell {

    @IBOutlet weak var count: UILabel!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var thumbernail: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
