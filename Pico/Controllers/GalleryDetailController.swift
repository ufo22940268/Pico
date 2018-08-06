//
//  GalleryDetailController.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/13.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit

class GalleryDetailController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet weak var image: UIImageView!
    var imageDate: Date?
    @IBOutlet weak var checkItem: UIBarButtonItem!
    
    var isSelected: Bool = false
    var imageEntity: Image!
    
    fileprivate func updateSelectView() {
        if isSelected {
            checkItem.tintColor = view.tintColor
        } else {
            checkItem.tintColor = UIColor.lightGray
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        // Do any additional setup after loading the view.
        if let imageDate = imageDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            navigationItem.title = dateFormatter.string(from: imageDate)
        }

        updateSelectView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onCheckItemClicked(_ sender: UIBarButtonItem) {
        isSelected = !isSelected
        updateSelectView()
    }
}

extension GalleryDetailController {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if type(of: viewController) == PickImageController.self {
            let vc = viewController as! PickImageController
            vc.imageGallery.updateSelection(image: imageEntity, select: isSelected)
        }
    }
}
