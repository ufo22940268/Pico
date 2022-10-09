import UIKit
import Photos

class Album {
    
    var collection: PHAssetCollection
    var fetchResult: PHFetchResult<PHAsset>!
    var items: [Image] = []
    
    // MARK: - Initialization
    
    init(collection: PHAssetCollection) {
        self.collection = collection
    }
    
    func populateItems() {
        self.items.removeAll()
        fetchResult.enumerateObjects({ (asset, count, stop) in
            if asset.mediaType == .image && self.isNormalSize(asset) {
                self.items.append(Image(asset: asset))
            }
        })
    }
    
    func isNormalSize(_ asset: PHAsset) -> Bool {
        return asset.pixelWidth < 8000 && asset.pixelHeight < 8000
    }
    
    func reload() {
        items = []
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        fetchResult = PHAsset.fetchAssets(in: collection, options: options)
        populateItems()
    }
    
    static func isScreenshot(image: Image) -> Bool {
        return ScreenDetector.isScreenshot(size: image.assetSize)
    }
    
    
    static func getRecentScreenshots(images: [Image]) -> [Image] {
        var screenshots = images
        screenshots = screenshots
            .filter { $0.asset.creationDate != nil }
            .filter { image in
            return (image.asset.creationDate ?? Date(timeIntervalSince1970: 0)) > Date() - TimeInterval(60*20)
        }.filter(isScreenshot)
        screenshots = screenshots.sorted(by: { (i1, i2) -> Bool in
            return i1.asset.creationDate! < i2.asset.creationDate!
        })
        return screenshots
    }
    
    static func selectAllPhotoAlbum(albums: [Album]) -> Album? {
        return albums.max(by: { (a1, a2) -> Bool in
            a1.items.count < a2.items.count
        })
    }
}
