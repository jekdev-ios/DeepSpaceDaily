import SwiftUI
import Combine

// MARK: - LazyImageView

public struct LazyImageView: View {
    let url: URL?
    let placeholder: Image
    let animation: Animation?
    let contentMode: ContentMode
    let maxWidth: CGFloat?
    
    @StateObject private var loader: LazyImageLoader
    
    public init(
        url: URL?,
        placeholder: Image = Image(systemName: "photo"),
        animation: Animation? = .default,
        contentMode: ContentMode = .fill,
        maxWidth: CGFloat? = nil
    ) {
        self.url = url
        self.placeholder = placeholder
        self.animation = animation
        self.contentMode = contentMode
        self.maxWidth = maxWidth
        
        _loader = StateObject(wrappedValue: LazyImageLoader(url: url))
    }
    
    public var body: some View {
        ZStack {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .center)))
                    .animation(animation, value: loader.image != nil)
            } else {
                placeholder
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .opacity(0.3)
            }
            
            if loader.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .frame(maxWidth: maxWidth)
        .onAppear {
            loader.load()
        }
        .onDisappear {
            loader.cancel()
        }
    }
}

// MARK: - LazyImageLoader

class LazyImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    
    private var url: URL?
    private var cancellable: AnyCancellable?
    
    init(url: URL?) {
        self.url = url
    }
    
    func load() {
        guard let url = url else { return }
        
        let urlString = url.absoluteString
        
        // Check if image is in cache
        if let cachedImage = ImageCache.shared.image(forKey: urlString) {
            self.image = cachedImage
            return
        }
        
        // If not in cache, load from network
        isLoading = true
        
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { [weak self] data, response -> UIImage? in
                guard let self = self,
                      let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let image = self.downsample(data: data) else {
                    return nil
                }
                
                // Cache the image
                ImageCache.shared.store(image, forKey: urlString)
                return image
            }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                self?.image = image
                self?.isLoading = false
            }
    }
    
    private func downsample(data: Data) -> UIImage? {
        // Create an image source
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            return UIImage(data: data)
        }
        
        // Calculate the desired dimension
        let maxDimensionInPixels: CGFloat = 800
        
        // Downsample
        let downsampledOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampledOptions) else {
            return UIImage(data: data)
        }
        
        return UIImage(cgImage: downsampledImage)
    }
    
    func cancel() {
        cancellable?.cancel()
        isLoading = false
    }
} 