//
//  CachedImage.swift
//  DeepSpaceDaily
//
//  Created by admin on 29/02/25.
//

import SwiftUI

/// Represents the phase of the image loading process
public enum CachedImagePhase {
    /// No image is loaded
    case empty
    
    /// An image successfully loaded
    case success(Image)
    
    /// Image loading failed
    case failure(Error)
    
    /// Returns a Boolean value indicating whether the image loading process succeeded
    public var image: Image? {
        if case .success(let image) = self {
            return image
        }
        return nil
    }
    
    /// Returns a Boolean value indicating whether the image loading process failed
    public var error: Error? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
}

/// A view that asynchronously loads and displays an image with caching
public struct CachedImage<Content: View>: View {
    private let url: URL?
    private let scale: CGFloat
    private let transaction: Transaction
    private let content: (CachedImagePhase) -> Content
    
    @State private var phase: CachedImagePhase = .empty
    @State private var isLoading = false
    
    /// Creates a cached image that displays content for the loaded image
    public init(url: URL?,
                scale: CGFloat = 1.0,
                transaction: Transaction = Transaction(),
                @ViewBuilder content: @escaping (CachedImagePhase) -> Content) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
    }
    
    public var body: some View {
        content(phase)
            .onAppear {
                loadImage()
            }
            .onChange(of: url) { _ in
                loadImage()
            }
    }
    
    private func loadImage() {
        guard !isLoading, let url = url else {
            phase = .empty
            return
        }
        
        let urlString = url.absoluteString
        
        // Check if image is in cache
        if let cachedImage = ImageCache.shared.image(forKey: urlString) {
            phase = .success(Image(uiImage: cachedImage))
            return
        }
        
        // If not in cache, load from network
        phase = .empty
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { isLoading = false }
            
            if let error = error {
                DispatchQueue.main.async {
                    withTransaction(transaction) {
                        phase = .failure(error)
                    }
                }
                return
            }
            
            guard let data = data, let downloadedImage = UIImage(data: data) else {
                DispatchQueue.main.async {
                    withTransaction(transaction) {
                        phase = .failure(NSError(domain: "CachedImage", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create image from data"]))
                    }
                }
                return
            }
            
            // Store in cache
            ImageCache.shared.store(downloadedImage, forKey: urlString)
            
            // Update UI on main thread
            DispatchQueue.main.async {
                withTransaction(transaction) {
                    phase = .success(Image(uiImage: downloadedImage))
                }
            }
        }.resume()
    }
}

// Convenience initializers
extension CachedImage {
    /// Creates a cached image that displays content for the loaded image using a URL string
    public init(urlString: String?,
                scale: CGFloat = 1.0,
                transaction: Transaction = Transaction(),
                @ViewBuilder content: @escaping (CachedImagePhase) -> Content) {
        let url = urlString.flatMap { URL(string: $0) }
        self.init(url: url, scale: scale, transaction: transaction, content: content)
    }
}

// Simple convenience view that wraps CachedImage
public struct SimpleCachedImage: View {
    private let url: URL?
    private let scale: CGFloat
    
    public init(url: URL?, scale: CGFloat = 1.0) {
        self.url = url
        self.scale = scale
    }
    
    public init(urlString: String?, scale: CGFloat = 1.0) {
        self.url = urlString.flatMap { URL(string: $0) }
        self.scale = scale
    }
    
    public var body: some View {
        CachedImage(url: url, scale: scale) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure:
                Text("Failed to load image")
                    .foregroundColor(.red)
            }
        }
    }
} 