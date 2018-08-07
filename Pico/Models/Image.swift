import UIKit
import Photos

/// Wrap a PHAsset
public class Image: Equatable {
    
    public let asset: PHAsset
    
    // MARK: - Initialization
    
    init(asset: PHAsset) {
        self.asset = asset
    }
    
    /// Resolve UIImage synchronously
    ///
    /// - Parameter size: The target size
    /// - Returns: The resolved UIImage, otherwise nil
    public func resolve(completion: @escaping (UIImage?) -> Void, targetWidth: CGFloat? = nil, deliveryMode: PHImageRequestOptionsDeliveryMode = .highQualityFormat) {
        var size:CGSize
        if targetWidth == nil {
            size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        } else {
            size = CGSize(width: targetWidth!, height: CGFloat(asset.pixelHeight)/CGFloat(asset.pixelWidth)*targetWidth!)
        }
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = deliveryMode
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: size,
            contentMode: .default,
            options: options) { (image, _) in
                completion(image)
        }
    }
}

class ImageMocker: Image {
    
    var uiImage: UIImage!
    
    init(image: UIImage) {
        super.init(asset: PHAsset())
        self.uiImage = image
    }

    override func resolve(completion: @escaping (UIImage?) -> Void, targetWidth: CGFloat?, deliveryMode: PHImageRequestOptionsDeliveryMode) {
        completion(uiImage)
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
    public static func resolve(images: [Image], completion: @escaping ([UIImage?]) -> Void, targetWidth: CGFloat? = nil, deliveryMode: PHImageRequestOptionsDeliveryMode = .highQualityFormat) {
        let dispatchGroup = DispatchGroup()
        var convertedImages = [Int: UIImage]()
        
        for (index, image) in images.enumerated() {
            dispatchGroup.enter()
            
            image.resolve(completion: { resolvedImage in
                if let resolvedImage = resolvedImage {
                    convertedImages[index] = resolvedImage
                }
                
                dispatchGroup.leave()
            }, targetWidth: targetWidth, deliveryMode: deliveryMode)
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
