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
    
    weak var viewController: UIViewController?
    let alertVC: UIAlertController!
    let okAction: UIAlertAction!
    
    init(viewController: UIViewController) {
        self.viewController = viewController
        alertVC = UIAlertController(title: "保存", message: "保存中", preferredStyle: .alert)
        okAction = UIAlertAction(title: "OK", style: .default)
        okAction.isEnabled = false
        alertVC.addAction(okAction)
    }
    
    func startSavingPhoto() {
        viewController?.present(alertVC, animated: true, completion: nil)
    }
    
    func saveToPhoto(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(afterSaveToPhoto(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func afterSaveToPhoto(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error == nil {
            alertVC.message = "图片已经保存到相册"
            okAction.isEnabled = true
        } else {
            alertVC.dismiss(animated: true, completion: nil)
        }
    }

}
