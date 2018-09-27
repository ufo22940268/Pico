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
        let allCells = getCells()
        let visibleCells = allCells.filter {$0.getFrame().intersects(visibleRect)}
        
        //Loading images
        if visibleCells.count > 0 {
            let lowerBound = allCells.enumerated().filter { (_, cell) -> Bool in
                cell === visibleCells.first!
            }.first!.offset
            let upperBound = allCells.enumerated().filter {$1 === visibleCells.last!}.first!.offset
            
            let cacheOffset = 3
            let cacheCells = allCells[max(lowerBound - cacheOffset, 0)...min(upperBound + cacheOffset, allCells.count - 1)]
            cacheCells.forEach {$0.loadImage()}

            let purgeCacheCells = allCells.filter {cell in !cacheCells.contains(where: { (cell2) -> Bool in
                cell === cell2
            })}
            purgeCacheCells.forEach {$0.unloadImage()}
        }
    }
}

protocol RecycleCell: class {
    
    func loadImage()
    
    func unloadImage()
    
    func getFrame() -> CGRect
}

protocol LoadingPlaceholder {
    func setupPlaceholder()
    func showPlaceholder()
    func contentViewVisible(_ show: Bool)
}

enum ViewTag : Int {
    case placeholder = 0x11
}

extension LoadingPlaceholder where Self : UIView {

    func setupPlaceholder() {
        let image = UIImageView(image: #imageLiteral(resourceName: "image-regular.pdf"))
        image.translatesAutoresizingMaskIntoConstraints = false
        addSubview(image)
        image.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0).isActive = true
        image.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 1.0).isActive = true
        image.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        image.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        image.contentMode = .center
        image.tag = ViewTag.placeholder.rawValue
        image.tintColor = UIColor.lightGray
        image.isHidden = true
    }
    
    fileprivate func getPlaceholder() -> UIView {
        return subviews.first(where: { (view) -> Bool in
            view.tag == ViewTag.placeholder.rawValue
        })!
    }
    
    func showPlaceholder() {
        getPlaceholder().isHidden = false
        contentViewVisible(false)
    }
    
    func showContentView() {
        getPlaceholder().isHidden = true
        contentViewVisible(true)
    }
}
