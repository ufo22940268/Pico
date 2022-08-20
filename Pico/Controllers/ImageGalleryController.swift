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

    let imageCellSize = 100*UIScreen.main.scale

    var images = [Image]() {
        willSet(newImages) {
            imageManager.stopCachingImagesForAllAssets()
            imageManager.startCachingImages(for: newImages.map {$0.asset},
                                            targetSize: CGSize(width: imageCellSize, height: imageCellSize),
                                            contentMode: .default,
                                            options: options)
        }
    }
    var selectImages = [Image]() 
    
    @IBOutlet var collection: UICollectionView!
    
    var delegate: SelectImageDelegate!
    var stack = ImageCacheStack()
    let maxSelectCount = 10
    
    let viewImageCache: NSCache<Image, UIImage> = { () -> NSCache<Image, UIImage> in
        let cache = NSCache<Image, UIImage>()
        cache.countLimit = 20
        return cache
    } ()
    
    let screenshotImageCache: NSCache<Image, UIImage> = { () -> NSCache<Image, UIImage> in
        let cache = NSCache<Image, UIImage>()
        cache.countLimit = 20
        return cache
    } ()

    let imageManager = PHCachingImageManager.default() as! PHCachingImageManager
    let options: PHImageRequestOptions = {
        let ops = PHImageRequestOptions()
        ops.deliveryMode = .highQualityFormat
        return ops
    }()

    
    
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
            imageManager.cancelImageRequest(PHImageRequestID(cell.tag))
        }
    
        let image = images[indexPath.item]
        let imageSize = CGSize(width: imageCellSize, height: imageCellSize)
        
        if let cacheImage = stack.find(image: image) {
            cell.image.image = cacheImage
        } else {
            let id = imageManager.requestImage(for: image.asset, targetSize: imageSize, contentMode: .default, options: options) { [weak self] (uiImage, _) in
                if let uiImage = uiImage {
                    cell.image.image = uiImage
                    self?.stack.push(bundle: (image, uiImage))
                }
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
    
    func loadForfViewImageCache(image: Image, toCache:  NSCache<Image, UIImage>? = nil) {
        let scale = UIScreen.main.bounds.width/CGFloat(image.asset.pixelWidth)
        let imageSize = CGSize(width: image.asset.pixelWidth, height: image.asset.pixelHeight).applying(CGAffineTransform(scaleX: scale, y: scale))
        PHImageManager.default().requestImage(for: image.asset, targetSize: imageSize, contentMode: .default, options: options) { [weak self] (uiImage, _) in
            let cache = toCache ?? self?.viewImageCache
            cache?.setObject(uiImage!, forKey: image)
        }
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
    
    func getImagesFromViewCache(images: [Image]? = nil) -> [UIImage] {
        let finalImages = images ?? selectImages
        var images = [UIImage]()
        for selectImage in finalImages {
            if let image = viewImageCache.object(forKey: selectImage) {
                images.append(image)
            }
        }
        return images
    }
    
    func getImagesFromScreenshotCache(images: [Image]) -> [UIImage] {
        var ar = [UIImage]()
        for selectImage in images {
            if let image = screenshotImageCache.object(forKey: selectImage) {
                ar.append(image)
            }
        }
        return ar
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectImage = images[indexPath.item]
        if selectImages.contains(selectImage) {
            selectImages.remove(at: selectImages.index(of: selectImage)!)
            viewImageCache.removeObject(forKey: selectImage)
        } else {
            guard selectImages.count < maxSelectCount  else {
                let ac = UIAlertController(title: nil, message: "最多只能选择\(maxSelectCount)张图片", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "ok", style: .default))
                self.present(ac, animated: true, completion: nil)
                return
            }
            selectImages.append(selectImage)
            
            loadForfViewImageCache(image: selectImage)
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
