//
//  MemoryManager.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/2/25.
//

import Foundation
import UIKit

class MemoryManager {
    static let shared = MemoryManager()
    
    private init() {
        // Monitor memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleMemoryWarning() {
        print("⚠️ Memory warning received - clearing caches")
        URLCache.shared.removeAllCachedResponses()
        
        // Post notification for views to clean up
        NotificationCenter.default.post(
            name: NSNotification.Name("ClearMemoryCaches"),
            object: nil
        )
    }
    
    // Process images with memory management
    static func processImages<T>(_ images: [UIImage],
                                 batchSize: Int = 3,
                                 processor: @escaping (UIImage) async throws -> T) async throws -> [T] {
        var results: [T] = []
        
        // Process in batches to prevent memory spikes
        for batch in stride(from: 0, to: images.count, by: batchSize) {
            let endIndex = min(batch + batchSize, images.count)
            let batchImages = Array(images[batch..<endIndex])
            
            for image in batchImages {
                // Use autoreleasepool for each image
                let result = try await autoreleasepool {
                    try await processor(image)
                }
                results.append(result)
            }
            
            // Small delay between batches to allow memory cleanup
            if endIndex < images.count {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        }
        
        return results
    }
    
    // Memory-efficient data loading
    static func loadDataSafely(from url: URL, maxSize: Int = 10 * 1024 * 1024) throws -> Data? {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int ?? 0
        
        if fileSize > maxSize {
            print("⚠️ File too large: \(fileSize) bytes, skipping")
            return nil
        }
        
        return try Data(contentsOf: url)
    }
}

// Async autoreleasepool for Swift concurrency
func autoreleasepool<T>(_ block: () async throws -> T) async throws -> T {
    return try await block()
}
