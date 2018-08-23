//
//  PickImageController.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/3.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit
import Photos

class PickImageController: UIViewController, SelectImageDelegate, PHPhotoLibraryChangeObserver, AlbumSelectDelegator {
    
    var imageGallery: ImageGalleryController!
    @IBOutlet weak var longScreenShotItem: UIBarButtonItem!
    @IBOutlet weak var movieItem: UIBarButtonItem!
    @IBOutlet weak var doneItem: UIBarButtonItem!
    @IBOutlet weak var cancelItem: UIBarButtonItem!
    var pickNavigationButton: PickNavigationButton!
    var selectAlbumController: SelectAlbumController!
    
    let library = ImagesLibrary()
    var selectAlbum: Album!
    var photoLibrary:PHPhotoLibrary!
    var recentScreenshots: [Image]!
    
    @IBOutlet weak var selectAlbumContainer: UIView!
    
    var scrollUpAnimation: UIViewPropertyAnimator?
    var scrollDownAnimation: UIViewPropertyAnimator?
    @IBOutlet weak var recentScreenshotItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickNavigationButton = UINib(nibName: "PickNavigationButton", bundle: nil).instantiate(withOwner: self, options: nil).first as! PickNavigationButton
        pickNavigationButton.addOnClickListener(target: self, action: #selector(onClickSelectAlbum))
        navigationItem.titleView = pickNavigationButton
        
        PHPhotoLibrary.requestAuthorization { status in
            self.reloadAlbums()
        }
        
        photoLibrary = PHPhotoLibrary.shared()
        photoLibrary.register(self)                
    }
    
    @objc func onClickSelectAlbum(_ sender: PickNavigationButton) {
        if let scrollUpAnimation = scrollUpAnimation, let scrollDownAnimation = scrollDownAnimation, scrollUpAnimation.state == .active || scrollDownAnimation.state == .active  {
            return
        }        
        
        pickNavigationButton.toggle(sender)
        if (pickNavigationButton.isSelected) {
            showSelectAlbumViewController()
        } else {
            hideSelectAlbumViewController()
        }
    }
    
    func onAlbumSelected(album: Album) {
        self.selectAlbum = album
        pickNavigationButton.isSelected = false
        hideSelectAlbumViewController()
        reloadSelectAlbum()
    }
    
    func showSelectAlbumViewController() {
        scrollUpAnimation = UIViewPropertyAnimator(duration: 0.15, curve: .easeIn, animations: {
            self.selectAlbumContainer.frame = self.selectAlbumContainer.frame.offsetBy(dx: 0, dy: -self.selectAlbumContainer.frame.height)
        })
        scrollUpAnimation!.startAnimation()
        
        navigationController?.toolbar.isHidden = true
    }
    
    func hideSelectAlbumViewController() {
        scrollDownAnimation = UIViewPropertyAnimator(duration: 0.15, curve: .easeIn, animations: {
            self.selectAlbumContainer.frame = self.selectAlbumContainer.frame.offsetBy(dx: 0, dy: self.selectAlbumContainer.frame.height)
        })
        scrollDownAnimation!.startAnimation()
        navigationController?.toolbar.isHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func reloadAlbums() {
        self.library.reload {
            guard self.library.albums.count > 0 else {
                return
            }
            
            if self.selectAlbum == nil {
                self.selectAlbum = self.library.albums.filter { $0.collection.assetCollectionSubtype == .smartAlbumUserLibrary }.first ?? self.library.albums.first!
            } else {
                self.selectAlbum = self.library.albums.filter { $0.collection.localIdentifier == self.selectAlbum.collection.localIdentifier}.first ?? self.selectAlbum
            }
            
            let screenshots = Album.selectAllPhotoAlbum(albums: self.library.albums)?.getRecentScreenshots()
            self.recentScreenshotItem.isEnabled = (screenshots?.count ?? 0) >= 2
            self.recentScreenshots = screenshots
            if let recentScreenshots = self.recentScreenshots {
                recentScreenshots.forEach {self.imageGallery.loadForfViewImageCache(image: $0, toCache: self.imageGallery.screenshotImageCache)}
            }
            
            self.reloadSelectAlbum()
            
            self.selectAlbumController.albums = self.library.albums.sorted(by: { (a1, a2) -> Bool in
                return a1.collection.localizedTitle == "所有照片"
            })
            self.selectAlbumController.tableView.reloadData()
        }
    }
    
    func reloadSelectAlbum() {
        pickNavigationButton.title.text = selectAlbum.collection.localizedTitle
        imageGallery.images = selectAlbum.items
        imageGallery.selectImages.removeAll()
        imageGallery.collection.reloadData()
    }
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.sync {
            self.reloadAlbums()
        }
    }
    
    fileprivate func updateTabbarItems(_ selectedImages: [Image]) {
        let enabled = selectedImages.count > 1
        cancelItem.isEnabled = enabled
        doneItem.isEnabled = enabled
        
        if (selectedImages.count > 1) {
            let firstSize = selectedImages.first!
            let equalLength = selectedImages[1..<selectedImages.count].filter{
                $0.asset.pixelHeight != firstSize.asset.pixelHeight && $0.asset.pixelWidth != firstSize.asset.pixelWidth
                }.isEmpty
            
            let isScreenshot = (selectedImages.filter {img in !CGSize(width: img.asset.pixelWidth, height: img.asset.pixelHeight).isScreenshot()}).isEmpty
            
            longScreenShotItem.isEnabled = isScreenshot
            movieItem.isEnabled = equalLength
        } else {
            longScreenShotItem.isEnabled = false
            movieItem.isEnabled = false
        }
    }
    
    func onImageSelected(selectedImages: [Image]) {
        updateTabbarItems(selectedImages)
    }
    
    @IBAction func onDone(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "compose", sender: self)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "imageGallery":
            imageGallery = segue.destination as! ImageGalleryController
            imageGallery.delegate = self
        case "composeNormal":
            let compose = segue.destination as! ComposeController
            compose.type = .normal
            compose.loadedImages = imageGallery.selectImages
            
            compose.loadUIImageHandler = { [weak self] () -> Void in
                self?.imageGallery.getImagesFromViewCache(images: self?.imageGallery.selectImages) {
                    compose.loadedUIImages = $0
                }
            }
        case "composeScreenshot":
            let compose = segue.destination as! ComposeController
            compose.type = .screenshot
            compose.loadedImages = imageGallery.selectImages.sorted(by: { (img1, img2) -> Bool in
                if let d1 = img1.asset.creationDate, let d2 = img2.asset.creationDate {
                    return d1 < d2
                } else {
                    return true
                }
            }) 
 
            compose.loadUIImageHandler = { [weak self] () -> Void in
                self?.imageGallery.getImagesFromViewCache(images: compose.loadedImages) {
                    compose.loadedUIImages = $0
                }
            }
        case "composeRecentScreenshot":
            let compose = segue.destination as! ComposeController
            compose.type = .screenshot
            compose.loadedImages = recentScreenshots
            compose.loadUIImageHandler = { [weak self] () -> Void in
                self?.imageGallery.getImagesFromViewCache(images: self?.recentScreenshots) {
                    compose.loadedUIImages = $0
                }
            }
        case "composeMovie":
            let compose = segue.destination as! ComposeController
            compose.type = .movie
            compose.loadedImages = imageGallery.selectImages
            compose.loadUIImageHandler = { [weak self] () -> Void in
                self?.imageGallery.getImagesFromViewCache(images: self?.imageGallery.selectImages) {
                    compose.loadedUIImages = $0
                }
            }
        case "selectAlbum":
            selectAlbumController = segue.destination as! SelectAlbumController
            selectAlbumController.selectDelegator = self
        default:
            break
        }
    }
    
    @IBAction func onClickCanncel(_ sender: UIBarButtonItem) {
        imageGallery.resetSelection()
        sender.isEnabled = false
        updateTabbarItems(imageGallery.selectImages)
    }
    

}
