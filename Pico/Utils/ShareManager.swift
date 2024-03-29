//
//  ShareManager.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/27.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import MonkeyKing

protocol ShareImageGenerator: class {
    func generateImage(callback: @escaping (UIImage) -> Void)
}

class ShareManager: NSObject {
    
    enum ShareDestination {
        case session, timeline
    }
    
    weak var viewController: UIViewController?

    let alertVC: UIAlertController!
    let okAction: UIAlertAction!
    
    
    var actionController: UIAlertController!
    
    weak var imageGenerator: ShareImageGenerator?
    
    init(viewController: UIViewController) {
        self.viewController = viewController
        self.imageGenerator = viewController as? ShareImageGenerator
        alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
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
            self.showLoading(label: "分享中...")
            self.generateImage(complete: {[weak self]  image in
                self?.dismissLoading()
                self?.shareToWechat(image: image, destination: .session)
            })
        }))
        alert.addAction(UIAlertAction(title: "分享到朋友圈", style: .default, handler: { _ in
            self.showLoading(label: "分享中...")
            self.generateImage(complete: {[weak self]  image in
                self?.dismissLoading()
                self?.shareToWechat(image: image, destination: .timeline)
            })
        }))
        alert.addAction(UIAlertAction(title: "下载到相册", style: .default, handler: { _ in
            self.showLoading(label: "保存中..")
            self.generateImage(complete: {[weak self]  image in
                self?.alertVC.message = "图片已经保存到相册"
                self?.okAction.isEnabled = true
                self?.saveToPhoto(image: image)
            })
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        return alert
    }
    
    func showLoading(label: String) {
        alertVC.message = label
        viewController?.present(alertVC, animated: true, completion: nil)
    }
    
    func dismissLoading() {
        alertVC.dismiss(animated: true, completion: nil)
    }
        
    func showActions() {
        if let viewController = viewController {
            viewController.present(actionController, animated: true, completion: nil)
        }
    }
    
    func saveToPhoto(image: UIImage) {
        if UIDevice.current.isSimulator {
            raise(SIGTRAP)
            print("saved image with size \(image.size) to photos")
        } else {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(afterSaveToPhoto(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }

    func shareToWechat(image: UIImage, destination: ShareDestination) {
        var monkeyMessage: MonkeyKing.Message
        if destination == .session {
            monkeyMessage = MonkeyKing.Message.weChat(.session(info: (
                title: nil,
                description: nil,
                thumbnail: image.thumbnail(),
                media: .image(image)
            )))
        } else {
            monkeyMessage = MonkeyKing.Message.weChat(.timeline(info: (
                title: nil,
                description: nil,
                thumbnail: image.thumbnail(),
                media: .image(image)
            )))
        }
        
        MonkeyKing.deliver(monkeyMessage) { success in
            print("shareURLToWeChatSession success: \(success)")
        }
    }
    
    @objc func afterSaveToPhoto(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error == nil {
            alertVC.message = "图片已经保存到相册"
            okAction.isEnabled = true
        } else {
            print("save image error: \(String(describing: error))")
            alertVC.dismiss(animated: true, completion: nil)
        }
    }

}
