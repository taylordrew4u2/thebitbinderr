//
//  ImageLoader.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/2/25.
//

import UIKit
import SwiftUI
import Combine

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    
    private var imageCache = NSCache<NSString, UIImage>()
    private static let maxCacheSize = 50 * 1024 * 1024 // 50MB
    private static let maxImageDimension: CGFloat = 2048 // Resize large images
    
    init() {
        imageCache.totalCostLimit = ImageLoader.maxCacheSize
        
        // Clear cache on memory warning
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func clearCache() {
        imageCache.removeAllObjects()
    }
    
    func loadImage(from data: Data) {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if let image = UIImage(data: data) {
                let resizedImage = self.resizeImageIfNeeded(image)
                
                DispatchQueue.main.async {
                    self.image = resizedImage
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let maxDimension = max(image.size.width, image.size.height)
        
        if maxDimension <= ImageLoader.maxImageDimension {
            return image
        }
        
        let scale = ImageLoader.maxImageDimension / maxDimension
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// Autoreleasepool wrapper for batch operations
extension ImageLoader {
    static func processBatchImages(_ images: [UIImage], completion: @escaping ([UIImage]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var processedImages: [UIImage] = []
            
            for image in images {
                autoreleasepool {
                    let loader = ImageLoader()
                    let resized = loader.resizeImageIfNeeded(image)
                    processedImages.append(resized)
                }
            }
            
            DispatchQueue.main.async {
                completion(processedImages)
            }
        }
    }
}
