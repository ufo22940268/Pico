import UIKit
import Photos
import Vision

extension Array where Element: FloatingPoint {
    
    func sum() -> Element {
        return self.reduce(0, +)
    }
    
    func avg() -> Element {
        return self.sum() / Element(self.count)
    }
    
    func std() -> Element {
        let mean = self.avg()
        let v = self.reduce(0, { $0 + ($1-mean)*($1-mean) })
        return sqrt(v / (Element(self.count) - 1))
    }
}
/// Wrap a PHAsset
public class Image: Equatable {
    
    public var asset: PHAsset
    let cacheImageManager:PHCachingImageManager = {
        let manager = PHCachingImageManager.default() as! PHCachingImageManager
        manager.allowsCachingHighQualityImages = true
        return manager
    } ()
    let imageManager = PHImageManager.default()
    
    var cacheOptions:PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        return options
    }
    
    var assetSize:CGSize {
        return CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
    }
    
    // MARK: - Initialization
    
    init(asset: PHAsset) {
        self.asset = asset
    }
    
    func cache() {
        let width = UIScreen.main.pixelSize.width
        let height = CGFloat(asset.pixelHeight)/CGFloat(asset.pixelWidth)*width
        cacheImageManager.startCachingImages(for: [asset], targetSize: CGSize(width: width, height: height), contentMode: .aspectFill, options: cacheOptions)
    }
    
    func uncache() {
        let width = UIScreen.main.pixelSize.width
        let height = CGFloat(asset.pixelHeight)/CGFloat(asset.pixelWidth)*width
        cacheImageManager.stopCachingImages(for: [asset], targetSize: CGSize(width: width, height: height), contentMode: .aspectFill, options: cacheOptions)
    }
    
    /// Resolve UIImage synchronously
    ///
    /// - Parameter size: The target size
    /// - Returns: The resolved UIImage, otherwise nil
    public func resolve(completion: @escaping (UIImage?) -> Void, targetWidth: CGFloat? = nil, targetSize: CGSize? = nil, deliveryMode: PHImageRequestOptionsDeliveryMode = .highQualityFormat, resizeMode: PHImageRequestOptionsResizeMode = .fast, contentMode: PHImageContentMode = .default, isSynchronize: Bool = false, cache:Bool = false) -> Int32 {
        var size:CGSize
        
        if targetSize != nil {
            size = targetSize!
        } else if targetWidth != nil {
            size = CGSize(width: targetWidth!, height: CGFloat(assetSize.height)/CGFloat(assetSize.width)*targetWidth!)
        } else {
            size = CGSize(width: assetSize.width, height: assetSize.height)
        }
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = deliveryMode
        options.resizeMode = resizeMode
        options.isSynchronous = isSynchronize
        
        let manager = cache ? cacheImageManager : imageManager
        return manager.requestImage(
            for: asset,
            targetSize: size,
            contentMode: contentMode,
            options: options) { (image, _) in
                completion(image)
        }
    }
}

class ImageMocker: Image {
    
    var uiImage: UIImage!
    
    override var assetSize: CGSize {
        return uiImage.size
    }
    
    init(image: UIImage) {
        super.init(asset: PHAsset())
        self.uiImage = image
    }
    
    override func resolve(completion: @escaping (UIImage?) -> Void, targetWidth: CGFloat?, targetSize: CGSize?, deliveryMode: PHImageRequestOptionsDeliveryMode, resizeMode: PHImageRequestOptionsResizeMode, contentMode: PHImageContentMode, isSynchronize: Bool = false, cache:Bool = false) -> Int32 {
        completion(uiImage)
        return Int32.random(in: 1...10000)
    }
}

// MARK: - UIImage

extension Image {
            
    /// Resolve an array of Image
    ///
    /// - Parameters:
    ///   - images: The array of Image
    ///   - size: The target size for all images
    ///   - completion: Called when operations completion
    public static func resolve(images: [Image], targetWidth: CGFloat? = nil, resizeMode: PHImageRequestOptionsResizeMode = .fast,completion: @escaping ([UIImage?]) -> Void) {
        let dispatchGroup = DispatchGroup()
        var convertedImages = [Int: UIImage]()
        
        for (index, image) in images.enumerated() {
            dispatchGroup.enter()
            
            image.resolve(completion: { resolvedImage in
                if let resolvedImage = resolvedImage {
                    convertedImages[index] = resolvedImage
                }
                
                dispatchGroup.leave()
            }, targetWidth: targetWidth, deliveryMode: .highQualityFormat, resizeMode: resizeMode)
        }
        
        dispatchGroup.notify(queue: .main, execute: {
            let sortedImages = convertedImages
                .sorted(by: { $0.key < $1.key })
                .map({ $0.value })
            completion(sortedImages)
        })
    }
}

extension Image {
    
    static func detectType(image: UIImage, complete: @escaping (AssetImageType) -> Void) {
        ImageClassifier(image: image).detectType(complete: complete)
    }
}


// MARK: - Equatable

public func == (lhs: Image, rhs: Image) -> Bool {
    return lhs.asset == rhs.asset
}

enum AssetImageType {
    case normal, movie
}

class ImageClassifier {
    
    var image: UIImage!
    let movieResolutions = [
        ScreenDetector.allScreenshotSizes.map{CGSize(width: $0.height, height: $0.width)},
        [CGSize(width: 1920, height: 1080), CGSize(width: 1280, height: 720)]
    ].joined()
    
    init(image: UIImage) {
        self.image = image
    }
    
    func charactersInMovie(_ characters: [VNRectangleObservation]) -> Bool {
        let heights = characters.map {$0.topLeft.y - $0.bottomLeft.y}
        let ys = characters.map {$0.topLeft.y}
        let torlerence = CGFloat(0.01)
        print("heights: \(heights.std()), ys: \(ys.std())")
        return heights.std() < torlerence && ys.std() < torlerence
    }
    
    func conformsToMovieResolution() -> Bool {
        let size = image.size
        return movieResolutions.contains(size)
    }
    
    func detectType(complete: @escaping (AssetImageType) -> Void) {
        let request = VNDetectTextRectanglesRequest { (request, error) in
            var type: AssetImageType = .normal
            if let result = request.results?.first, let characterBoxes = (result as! VNTextObservation).characterBoxes {
                if self.conformsToMovieResolution() && self.charactersInMovie(characterBoxes) {
                    type = .movie
                }
            } else {
                print("detect type error: \(error.debugDescription)")
            }
            
            complete(type)
        }
        request.regionOfInterest = CGRect(origin: CGPoint.zero, size: CGSize(width: 1, height: 0.5))
        request.reportCharacterBoxes = true
        
        try! VNImageRequestHandler(cgImage: image.cgImage!, options: [:]).perform([request])
    }
}
