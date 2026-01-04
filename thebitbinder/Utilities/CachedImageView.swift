import SwiftUI
import UIKit

final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private init() {
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }
    func set(_ image: UIImage, forKey key: String, cost: Int = 0) {
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
}

struct CachedImageView: View {
    let fileURL: URL
    let placeholder: AnyView
    let contentMode: ContentMode
    let cornerRadius: CGFloat

    @State private var image: UIImage?

    init(fileURL: URL,
         placeholder: AnyView = AnyView(Color.gray),
         contentMode: ContentMode = .fill,
         cornerRadius: CGFloat = 8) {
        self.fileURL = fileURL
        self.placeholder = placeholder
        self.contentMode = contentMode
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .cornerRadius(cornerRadius)
            } else {
                placeholder
                    .cornerRadius(cornerRadius)
                    .task { await load() }
            }
        }
    }

    private func load() async {
        let cacheKey = fileURL.lastPathComponent
        if let cached = ImageCache.shared.image(forKey: cacheKey) {
            self.image = cached
            return
        }
        await withTaskGroup(of: UIImage?.self) { group in
            group.addTask {
                let path = fileURL.path
                if let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                   let img = UIImage(data: data) {
                    // downscale large images for grid
                    let maxDim: CGFloat = 512
                    let scaled = downscale(image: img, maxDimension: maxDim)
                    ImageCache.shared.set(scaled, forKey: cacheKey, cost: Int(scaled.pngData()?.count ?? 0))
                    return scaled
                }
                return nil
            }
            for await result in group {
                await MainActor.run { self.image = result }
            }
        }
    }
}

private func downscale(image: UIImage, maxDimension: CGFloat) -> UIImage {
    let maxDim = max(image.size.width, image.size.height)
    if maxDim <= maxDimension { return image }
    let scale = maxDimension / maxDim
    let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
    return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
}
