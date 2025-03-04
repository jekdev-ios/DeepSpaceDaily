//
//  StorageAdapter.swift
//  DeepSpaceDaily
//
//  Created by admin on 03/03/25.
//

import Foundation

/// Type alias for primitive types that can be stored directly in UserDefaults
typealias UserDefaultsPrimitive = Any

/// Protocol defining the low-level storage operations
protocol StorageAdapter {
    /// Save a value to storage
    /// - Parameters:
    ///   - value: The value to store
    ///   - key: The key to store it under
    /// - Throws: StorageError if the operation fails
    func save<T: Encodable>(value: T, forKey key: String) throws
    
    /// Load a value from storage
    /// - Parameter key: The key to retrieve
    /// - Returns: The decoded value, or nil if not found
    /// - Throws: StorageError if the operation fails
    func load<T: Decodable>(forKey key: String) throws -> T?
    
    /// Check if a key exists in storage
    /// - Parameter key: The key to check
    /// - Returns: True if the key exists
    func contains(key: String) -> Bool
    
    /// Remove a value from storage
    /// - Parameter key: The key to remove
    /// - Throws: StorageError if the operation fails
    func remove(forKey key: String) throws
    
    /// Remove all values from storage
    /// - Throws: StorageError if the operation fails
    func removeAll() throws
}

/// An implementation of StorageAdapter that uses UserDefaults
class UserDefaultsAdapter: StorageAdapter {
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func save<T: Encodable>(value: T, forKey key: String) throws {
        // Handle primitive types directly
        // Check if value is a primitive type that UserDefaults can handle directly
        if let stringValue = value as? String {
            userDefaults.set(stringValue, forKey: key)
            return
        } else if let boolValue = value as? Bool {
            userDefaults.set(boolValue, forKey: key)
            return
        } else if let intValue = value as? Int {
            userDefaults.set(intValue, forKey: key)
            return
        } else if let doubleValue = value as? Double {
            userDefaults.set(doubleValue, forKey: key)
            return
        } else if let dataValue = value as? Data {
            userDefaults.set(dataValue, forKey: key)
            return
        } else if let dateValue = value as? Date {
            userDefaults.set(dateValue, forKey: key)
            return
        } else if let arrayValue = value as? [String] {
            userDefaults.set(arrayValue, forKey: key)
            return
        } else if let dictValue = value as? [String: String] {
            userDefaults.set(dictValue, forKey: key)
            return
        }
        
        // For complex types, encode to data
        do {
            let data = try JSONEncoder().encode(value)
            userDefaults.set(data, forKey: key)
        } catch {
            throw StorageError.serializationFailure(key: key, underlyingError: error)
        }
    }
    
    func load<T: Decodable>(forKey key: String) throws -> T? {
        // Check if key exists
        guard userDefaults.object(forKey: key) != nil else {
            return nil
        }
        
        // Handle primitive types
        if let primitive = userDefaults.object(forKey: key) as? T {
            return primitive
        }
        
        // Handle Data objects for complex types
        guard let data = userDefaults.data(forKey: key) else {
            throw StorageError.retrievalFailure(
                key: key,
                reason: "Value exists but is not compatible with requested type"
            )
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw StorageError.serializationFailure(key: key, underlyingError: error)
        }
    }
    
    func contains(key: String) -> Bool {
        return userDefaults.object(forKey: key) != nil
    }
    
    func remove(forKey key: String) throws {
        userDefaults.removeObject(forKey: key)
    }
    
    func removeAll() throws {
        if let bundleID = Bundle.main.bundleIdentifier {
            userDefaults.removePersistentDomain(forName: bundleID)
        } else {
            throw StorageError.operationFailure(
                operation: "removeAll",
                reason: "Bundle identifier not available"
            )
        }
    }
} 