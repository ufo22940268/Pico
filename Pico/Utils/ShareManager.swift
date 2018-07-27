//
//  ShareManager.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/27.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class ShareManager: NSObject {
    
    let viewController: UIViewController!
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func saveToPhoto(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(afterSaveToPhoto(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func afterSaveToPhoto(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            viewController.present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "保存成功", message: "图片已经保存到相册", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            viewController.present(ac, animated: true)
        }
    }

}
