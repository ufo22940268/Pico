//
//  RecycleList.swift
//  Pico
//
//  Created by Frank Cheng on 2018/9/21.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

protocol RecycleList {
    
    func getCells() -> [RecycleCell]
    
}

extension RecycleList where Self : UIStackView {
    
    
    func findIntersectCells(with rect: CGRect) -> [RecycleCell] {
        return getCells().filter {$0.getFrame().intersects(rect)}
    }    
    
    func loadImages(scrollView: UIScrollView) {
        let visibleRect = convert(scrollView.bounds.intersection(self.frame), from: scrollView)
        let visibleCells = getCells().filter {$0.getFrame().intersects(visibleRect)}
        
        let loadCells = visibleCells
        loadCells.forEach {$0.loadImage()}
        
        let unloadCells = getCells().filter {cell in !loadCells.contains(where: { (cell2) -> Bool in
            cell === cell2
        })}
        unloadCells.forEach {$0.unloadImage()}
    }
}

protocol RecycleCell: class {
    
    func loadImage()
    
    func unloadImage()
    
    func getFrame() -> CGRect
}
