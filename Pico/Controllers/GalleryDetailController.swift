//
//  GalleryDetailController.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/13.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit
import Photos

extension UIScrollView {
    var currentPage: Int {
        return Int((self.contentOffset.x + (0.5*self.frame.size.width))/self.frame.width)+1
    }
}

class GalleryDetailController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var checkItem: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var isSelected: Bool = false
    var imageEntity: Image!
    var imageEntities: [Image]!
    var selectedImageEntities: [Image]!
    var initialImage:Image?

    
    func isDev() -> Bool {
        return imageEntities == nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (isDev()) {
            let library = ImagesLibrary()
            library.reloadSync()
            let album = Album.selectAllPhotoAlbum(albums: library.albums)!
            imageEntity = album.items.first
            imageEntities = album.items
            selectedImageEntities = Array(album.items[0...3])
        }
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        collectionView.collectionViewLayout = layout
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        if let initialImage = initialImage {
            scrollTo(image: initialImage)
        }
        
        updateSelectView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.delegate = self
    }
    
    var currentImage:Image {
        return imageEntities[collectionView.currentPage - 1]
    }
    
    fileprivate func updateSelectView() {
        updateSelectView(for: imageEntities[collectionView.currentPage - 1])
    }

    fileprivate func updateSelectView(for image: Image) {
        let isSelected = selectedImageEntities.contains(image)
        if isSelected {
            checkItem.tintColor = view.tintColor
        } else {
            checkItem.tintColor = UIColor.lightGray
        }
        
        let imageDate = image.asset.creationDate
        if let imageDate = imageDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            navigationItem.title = dateFormatter.string(from: imageDate)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onCheckItemClicked(_ sender: UIBarButtonItem) {
        if selectedImageEntities.contains(currentImage) {
            selectedImageEntities.remove(at: selectedImageEntities.firstIndex(of: currentImage)!)
        } else {
            selectedImageEntities.append(currentImage)
        }
        updateSelectView()
    }
    
    func scrollTo(image: Image) {
        let indexOfImage = imageEntities.enumerated().filter {$0.element == image}.first!.offset
        collectionView.scrollToItem(at: IndexPath(row: indexOfImage, section: 0), at: .left, animated: false)
    }
}

extension GalleryDetailController {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if type(of: viewController) == PickImageController.self {
            let vc = viewController as! PickImageController
            vc.imageGallery.selectImages = selectedImageEntities
            vc.imageGallery.syncSelectedImagesToCollectionView()
            vc.imageGallery.updateAfterSelectionChanged()
        }
    }
}

extension GalleryDetailController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageEntities?.count ?? 0
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! GalleryDetailCell
        let image = imageEntities[indexPath.row]
        if cell.tag != 0 {
            PHImageManager.default().cancelImageRequest(Int32(cell.tag))
        }
        
        let seq = image.resolve(completion: {uiImage in
            cell.imageView.image = uiImage
        })
        cell.tag = Int(seq)
        return cell
    }
}

extension GalleryDetailController: UICollectionViewDelegateFlowLayout {
 
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateSelectView(for: imageEntities[collectionView.currentPage - 1])
    }
}
