//
//  PickImageController.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/3.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit
import Photos

private let reuseIdentifier = "PickCell"

protocol SelectImageDelegate {
    func onImageSelected(selectedImages: [Image])
}

class ImageGalleryController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIViewControllerPreviewingDelegate {

    let imageCellSize = 100*UIScreen.main.scale
    
    var images = [Image]()
    var selectImages = [Image]() 
    
    @IBOutlet var collection: UICollectionView!
    
    var delegate: SelectImageDelegate!
    let maxSelectCount = 50
    
    let imageManager = PHCachingImageManager.default() as! PHCachingImageManager
    
    let options: PHImageRequestOptions = {
        let ops = PHImageRequestOptions()
        ops.deliveryMode = .highQualityFormat
        ops.isNetworkAccessAllowed = true
        return ops
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.allowsMultipleSelection = true
        collection.register(UINib(nibName: "ImageCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
        registerForPreviewing(with: self, sourceView: collection)
    }
    
    func updateSelectImages() -> Bool {
        let newSelectImages = selectImages.filter {images.contains($0)}
        let updated = newSelectImages.count != selectImages.count
        selectImages = newSelectImages
        return updated
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateAfterSelectionChanged()
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func resetSelection() {
        selectImages.removeAll()
        collection.reloadItems(at: collection.indexPathsForVisibleItems)        
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return images.count
    }
    
    func getImageType(from image: Image) -> PickImageCell.ImageType {
        if Album.isScreenshot(image: image) {
            return .screenshot
        } else {
            return .none
        }
    }

    fileprivate func updateCellSelectedStatus(_ indexPath: IndexPath, _ cell: PickImageCell) {
        let sequence = getSelectSequence(image: images[indexPath.item])
        if cell.isSelected {
            if let sequence = sequence  {
                cell.select(number: sequence)
            }
        } else {
            cell.unselect()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PickImageCell
        
        let image = images[indexPath.item]
        let imageSize = CGSize(width: imageCellSize, height: imageCellSize)
        
        if cell.tag != 0 {
            imageManager.cancelImageRequest(PHImageRequestID(cell.tag))
        }
        
        let id = imageManager.requestImage(for: image.asset, targetSize: imageSize, contentMode: .default, options: options) {(uiImage, _) in
            if let uiImage = uiImage {
                cell.image.image = uiImage
            }
        }
        cell.tag = Int(id)
        
        cell.setImageType(getImageType(from: image))        
        
        updateCellSelectedStatus(indexPath, cell)
        
        return cell
    }
    
    func getSelectSequence(image: Image) -> Int? {
        return selectImages.index(of: image)
    }
    
    func getIndexPath(image: Image) -> IndexPath {
        return IndexPath(item: images.index(of: image)!, section: 0)
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        let controller = storyboard?.instantiateViewController(withIdentifier: "galleryDetail") as! GalleryDetailController
        if let peekCell = (collection.visibleCells.first { (cell) -> Bool in
            let point = cell.convert(location, from: collection)
            return cell.point(inside: point, with: nil)
            })
        {
            let image = images[(collection.indexPath(for: peekCell)?.item)!]
            controller.imageDate = image.asset.creationDate
            image.resolve(completion:  { (uiImage) in
                controller.image.image = uiImage
            })
            controller.imageEntity = image
            controller.isSelected = selectImages.contains(image) 
        }
        return controller
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        navigationController?.pushViewController(viewControllerToCommit, animated: true)
    }
    

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columnCount:CGFloat = 4
        let cellSpacing:CGFloat = 2
        let size = (collectionView.bounds.size.width - (columnCount - 1)*cellSpacing)/columnCount
        return CGSize(width: size, height: size)
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectImage = images[indexPath.item]
        if selectImages.count < 6 {
            selectImage.cache()
        }
        guard selectImages.count < maxSelectCount else {
            let ac = UIAlertController(title: nil, message: "最多只能选择\(maxSelectCount)张图片", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "ok", style: .default))
            self.present(ac, animated: true, completion: nil)
            return
        }
        
        selectImages.append(selectImage)
        
        updateAfterSelectionChanged()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let selectImage = images[indexPath.item]
        selectImage.uncache()
        if selectImages.contains(selectImage) {
            selectImages.remove(at: selectImages.index(of: selectImage)!)
        }

        updateAfterSelectionChanged()
    }
    
    func updateAfterSelectionChanged(reloadAll: Bool = false) {
        delegate.onImageSelected(selectedImages: selectImages)
        if reloadAll {
            self.collectionView?.reloadData()
        } else {
            for cell in collectionView.visibleCells {
                updateCellSelectedStatus(collectionView.indexPath(for: cell)!, cell as! PickImageCell)
            }
        }
    }

    func updateSelection(image: Image, select: Bool) {
        if select {
            if !selectImages.contains(image) {
                selectImages.append(image)
            }
        } else {
            if selectImages.contains(image) {
                selectImages.remove(at: selectImages.index(of: image)!)
            }
        }
    }
}
