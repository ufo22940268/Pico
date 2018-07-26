//
//  AutoConcate.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/14.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class AutoConcate {
    
    var cells: [ComposeCell]
    var images: [UIImage?]
    
    init(cells: [ComposeCell], images: [UIImage?]) {
        self.cells = cells
        self.images = images
    }
    
    func getCellByImage(image: UIImage) -> ComposeCell? {
        if let offset = (images.enumerated().filter{ $1 == image }).first?.offset {
            return cells[offset]
        }
        return nil
    }
    
    func scroll(cell:ComposeCell, percentage: CGFloat, adjust: CGFloat = 0) {
        let scrollY = percentage == 0 ? 0 : cell.frame.size.height*percentage + adjust
        print("scrollY", scrollY)
        if scrollY < 0 {
            cell.scrollY(ComposeCell.Position.below, scrollY)
        } else {
            cell.scrollY(ComposeCell.Position.above, scrollY)
        }
    }
    
}
