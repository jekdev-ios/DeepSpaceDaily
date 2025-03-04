//
//  ImageCache.swift
//  DeepSpaceDaily
//
//  Created by admin on 29/02/25.
//

import Foundation
import SwiftUI
import CommonCrypto

/// A cache that stores images in memory and on disk
class ImageCache {
    static let shared = ImageCache()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Set up memory cache
        memoryCache.countLimit = 100 // Maximum number of images to keep in memory
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
        
        // Set up disk cache directory
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache")
        
        // Create cache directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            } catch {
                print("Error creating cache directory: \(error)")
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Store an image in the cache
    func store(_ image: UIImage, forKey key: String) {
        // Store in memory cache
        memoryCache.setObject(image, forKey: key as NSString)
        
        // Store on disk
        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)
        if let data = image.jpegData(compressionQuality: 0.8) {
            do {
                try data.write(to: fileURL)
            } catch {
                print("Error writing image to disk: \(error)")
            }
        }
    }
    
    /// Retrieve an image from the cache
    func image(forKey key: String) -> UIImage? {
        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: key as NSString) {
            return cachedImage
        }
        
        // Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)
        if fileManager.fileExists(atPath: fileURL.path),
           let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            // Store back in memory cache for faster access next time
            memoryCache.setObject(image, forKey: key as NSString)
            return image
        }
        
        return nil
    }
    
    /// Remove an image from the cache
    func removeImage(forKey key: String) {
        // Remove from memory cache
        memoryCache.removeObject(forKey: key as NSString)
        
        // Remove from disk cache
        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
            } catch {
                print("Error removing image from disk: \(error)")
            }
        }
    }
    
    /// Clear all cached images
    func clearCache() {
        // Clear memory cache
        memoryCache.removeAllObjects()
        
        // Clear disk cache
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Error clearing disk cache: \(error)")
        }
    }
}

// MARK: - String Extension for MD5 Hashing
extension String {
    var md5Hash: String {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        
        _ = data.withUnsafeBytes {
            CC_MD5($0.baseAddress, CC_LONG(data.count), &digest)
        }
        
        return digest.map { String(format: "%02x", $0) }.joined()
    }
} 