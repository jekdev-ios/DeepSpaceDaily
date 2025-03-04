//
//  StorageWrapper.swift
//  DeepSpaceDaily
//
//  Created by admin on 03/03/25.
//

import Foundation

/// A wrapper that adds metadata to items stored in persistence
struct StorageWrapper<T: Codable>: Codable {
    /// The wrapped data
    let data: T
    
    /// When the data was stored
    let timestamp: Date
    
    /// Schema version for migration purposes
    let version: Int
    
    /// Time since storage in seconds
    var age: TimeInterval {
        return Date().timeIntervalSince(timestamp)
    }
    
    /// Check if the data is still fresh based on a TTL
    /// - Parameter ttl: Time-to-live in seconds
    /// - Returns: True if the data is still valid
    func isValid(ttl: TimeInterval) -> Bool {
        return age <= ttl
    }
    
    /// Create a new wrapper with the current timestamp
    /// - Parameters:
    ///   - data: The data to wrap
    ///   - version: Schema version (default: 1)
    init(data: T, version: Int = 1) {
        self.data = data
        self.timestamp = Date()
        self.version = version
    }
    
    /// Create a wrapper with a specific timestamp (useful for testing)
    /// - Parameters:
    ///   - data: The data to wrap
    ///   - timestamp: When the data was stored
    ///   - version: Schema version
    init(data: T, timestamp: Date, version: Int) {
        self.data = data
        self.timestamp = timestamp
        self.version = version
    }
} 