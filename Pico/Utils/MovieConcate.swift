//
//  MovieConcate.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/14.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class MovieConcate: AutoConcate {
    
    func scrollCells() {
        concateMovie()
    }
    
    
    fileprivate func concateMovie() {
        var movieScrolls = [UIImage:CGFloat]()
        for uiImage in images[1..<images.count] {
            MovieDetector(uiImage: uiImage).subtitleY { (y, _) in
                movieScrolls[uiImage!] = y
                if movieScrolls.count == self.images.count - 1 {
                    DispatchQueue.main.sync {
                        self.scrollMovieImages(movieScrolls: movieScrolls)
                    }
                }
            }
        }
    }
    
    func scrollMovieImages(movieScrolls: [UIImage:CGFloat]) {
        for (image, scrollY) in movieScrolls {
            let cell = getCellByImage(image: image)
            scroll(cell: cell!, percentage: CGFloat(-scrollY), adjust: 8)
        }
    }

}
