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

struct ImageCacheStack {
    
    var cacheImages = [(Image, UIImage)]()

    mutating func push(bundle: (Image, UIImage)) {
        cacheImages.append(bundle)
        if cacheImages.count > 40  {
            cacheImages.remove(at: 0)
        }
    }
    
    func find(image: Image) -> UIImage? {
        return (cacheImages.filter {$0.0 == image}).first?.1
    }
}

class ImageGalleryController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIViewControllerPreviewingDelegate {
    

    var images = [Image]()
    var selectImages = [Image]() 
    
    @IBOutlet var collection: UICollectionView!
    
    var delegate: SelectImageDelegate!
    var stack = ImageCacheStack()
    let maxSelectCount = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collection.register(UINib(nibName: "ImageCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
        registerForPreviewing(with: self, sourceView: collection)
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
    

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PickImageCell
        
        if cell.tag != 0 {
            PHImageManager.default().cancelImageRequest(PHImageRequestID(cell.tag))
        }
    
        let image = images[indexPath.item]
        let imageSize = CGSize(width: cell.image.frame.size.width*UIScreen.main.scale, height: cell.image.frame.size.height*UIScreen.main.scale)
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        
        if let cacheImage = stack.find(image: image) {
            cell.image.image = cacheImage
        } else {
            let id = PHImageManager.default().requestImage(for: image.asset, targetSize: imageSize, contentMode: .default, options: options) { [weak self] (uiImage, _) in
                cell.image.image = uiImage
                self?.stack.push(bundle: (image, uiImage!))
            }
            cell.tag = Int(id)
        }
        
        let sequence = getSelectSequence(image: images[indexPath.item])
        if let sequence = sequence  {
            cell.select(number: sequence)
        } else {
            cell.unselect()
        }
        
        return cell
    }
    
    func getSelectSequence(image: Image) -> Int? {
        return selectImages.index(of: image)
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
        if selectImages.contains(selectImage) {
            selectImages.remove(at: selectImages.index(of: selectImage)!)
        } else {
            guard selectImages.count < maxSelectCount  else {
                let ac = UIAlertController(title: nil, message: "最多只能选择\(maxSelectCount)张图片", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "ok", style: .default))
                self.present(ac, animated: true, completion: nil)
                return
            }
            selectImages.append(selectImage)
        }
        
        updateAfterSelectionChanged()
    }
    
    func updateAfterSelectionChanged() {
        delegate.onImageSelected(selectedImages: selectImages)
        
        UIView.animate(withDuration: 0.01, animations: {
            self.collection.performBatchUpdates({
                self.collection.reloadItems(at: self.collectionView!.indexPathsForVisibleItems)
            }, completion: nil)
        })
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
