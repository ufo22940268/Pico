//
//  ShareManager.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/27.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

protocol ShareImageGenerator: class {
    func generateImage(callback: @escaping (UIImage) -> Void)
}

class ShareManager: NSObject {
    
    weak var viewController: UIViewController?

    let alertVC: UIAlertController!
    let okAction: UIAlertAction!
    
    
    var actionController: UIAlertController!
    
    weak var imageGenerator: ShareImageGenerator?
    
    init(viewController: UIViewController) {
        self.viewController = viewController
        self.imageGenerator = viewController as! ShareImageGenerator
        alertVC = UIAlertController(title: "保存", message: "保存中", preferredStyle: .alert)
        okAction = UIAlertAction(title: "OK", style: .default)
        okAction.isEnabled = false
        alertVC.addAction(okAction)
        
        super.init()
        actionController = self.buildActionController()
    }
    
    func generateImage(complete: @escaping (UIImage) -> Void) {
        self.imageGenerator?.generateImage(callback: { (image) in
            complete(image)
        })
    }
    
    func buildActionController() -> UIAlertController {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "微信分享给好友", style: .default, handler: { _ in
            self.generateImage(complete: {[weak self]  image in
                self?.shareToWechat(image: image, scene: WXSceneSession)
            })
        }))
        alert.addAction(UIAlertAction(title: "分享到朋友圈", style: .default, handler: { _ in
            self.generateImage(complete: {[weak self]  image in
                self?.shareToWechat(image: image, scene: WXSceneTimeline)
            })
        }))
        alert.addAction(UIAlertAction(title: "下载到相册", style: .default, handler: { _ in
            self.generateImage(complete: {[weak self]  image in
                self?.saveToPhoto(image: image)
            })
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        return alert
    }
    
    func startSavingPhoto() {
        viewController?.present(alertVC, animated: true, completion: nil)
    }
    
    func showActions() {
        if let viewController = viewController {
            viewController.present(actionController, animated: true, completion: nil)
        }
    }
    
    func saveToPhoto(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(afterSaveToPhoto(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    func shareToWechat(image: UIImage, scene: WXScene) {
        let message = WXMediaMessage()
        message.setThumbImage(image.thumbnail())
        let imageObj = WXImageObject()
        imageObj.imageData = UIImagePNGRepresentation(image)
        message.mediaObject = imageObj
        
        let req = SendMessageToWXReq()
        req.message = message
        req.bText = false
        req.scene = Int32(scene.rawValue)
        WXApi.send(req)
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
