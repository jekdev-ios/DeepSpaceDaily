//
//  CachedAsyncImage.swift
//  DeepSpaceDaily
//
//  Created by admin on 29/02/25.
//

import SwiftUI

/// A SwiftUI view that asynchronously loads and displays an image with caching
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let scale: CGFloat
    private let transaction: Transaction
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    
    /// Initialize with a URL and content/placeholder closures
    init(url: URL?,
         scale: CGFloat = 1.0,
         transaction: Transaction = Transaction(),
         @ViewBuilder content: @escaping (Image) -> Content,
         @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let loadedImage = loadedImage {
                content(Image(uiImage: loadedImage))
            } else {
                placeholder()
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: url) { _ in
            loadImage()
        }
    }
    
    private func loadImage() {
        guard !isLoading, let url = url else { return }
        
        let urlString = url.absoluteString
        
        // Check if image is in cache
        if let cachedImage = ImageCache.shared.image(forKey: urlString) {
            loadedImage = cachedImage
            return
        }
        
        // If not in cache, load from network
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { isLoading = false }
            
            guard let data = data, error == nil,
                  let downloadedImage = UIImage(data: data) else {
                return
            }
            
            // Store in cache
            ImageCache.shared.store(downloadedImage, forKey: urlString)
            
            // Update UI on main thread
            DispatchQueue.main.async {
                withTransaction(transaction) {
                    loadedImage = downloadedImage
                }
            }
        }.resume()
    }
}

// Convenience initializers
extension CachedAsyncImage {
    /// Initialize with a URL string and content/placeholder closures
    init(urlString: String?,
         scale: CGFloat = 1.0,
         transaction: Transaction = Transaction(),
         @ViewBuilder content: @escaping (Image) -> Content,
         @ViewBuilder placeholder: @escaping () -> Placeholder) {
        let url = urlString.flatMap { URL(string: $0) }
        self.init(url: url, scale: scale, transaction: transaction, content: content, placeholder: placeholder)
    }
}

// Phase-based API similar to SwiftUI's AsyncImage
extension CachedAsyncImage where Content == Image, Placeholder == _ConditionalContent<ProgressView<EmptyView, EmptyView>, EmptyView> {
    /// Initialize with a URL and phase-based content
    init(url: URL?, scale: CGFloat = 1.0) {
        self.init(url: url, scale: scale) { image in
            image
        } placeholder: {
            if url != nil {
                ProgressView()
            } else {
                EmptyView()
            }
        }
    }
    
    /// Initialize with a URL string and phase-based content
    init(urlString: String?, scale: CGFloat = 1.0) {
        let url = urlString.flatMap { URL(string: $0) }
        self.init(url: url, scale: scale)
    }
} 