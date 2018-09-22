import UIKit
import Photos

/// Wrap a PHAsset
public class Image: Equatable {
    
    public var asset: PHAsset
    
    var assetSize:CGSize {
        return CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
    }
    
    // MARK: - Initialization
    
    init(asset: PHAsset) {
        self.asset = asset
    }
    
    /// Resolve UIImage synchronously
    ///
    /// - Parameter size: The target size
    /// - Returns: The resolved UIImage, otherwise nil
    public func resolve(completion: @escaping (UIImage?) -> Void, targetWidth: CGFloat? = nil, deliveryMode: PHImageRequestOptionsDeliveryMode = .highQualityFormat, resizeMode: PHImageRequestOptionsResizeMode = .fast, contentMode: PHImageContentMode = .default) -> Int32 {
        var size:CGSize
        if targetWidth == nil {
            size = CGSize(width: assetSize.width, height: assetSize.height)
        } else {
            size = CGSize(width: targetWidth!, height: CGFloat(assetSize.height)/CGFloat(assetSize.width)*targetWidth!)
        }
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = deliveryMode
        options.resizeMode = resizeMode
        
        return PHImageManager.default().requestImage(
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

    override func resolve(completion: @escaping (UIImage?) -> Void, targetWidth: CGFloat?, deliveryMode: PHImageRequestOptionsDeliveryMode, resizeMode: PHImageRequestOptionsResizeMode, contentMode: PHImageContentMode) -> Int32 {
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

// MARK: - Equatable

public func == (lhs: Image, rhs: Image) -> Bool {
    return lhs.asset == rhs.asset
}
