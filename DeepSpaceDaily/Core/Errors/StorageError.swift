//
//  StorageError.swift
//  DeepSpaceDaily
//
//  Created by admin on 03/03/25.
//

import Foundation

/// Error types specific to storage operations
enum StorageError: Error {
    case serializationFailure(key: String, underlyingError: Error)
    case retrievalFailure(key: String, reason: String)
    case staleData(key: String, age: TimeInterval)
    case operationFailure(operation: String, reason: String)
}

extension StorageError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .serializationFailure(let key, let error):
            return "Failed to serialize data for key '\(key)': \(error.localizedDescription)"
        case .retrievalFailure(let key, let reason):
            return "Failed to retrieve data for key '\(key)': \(reason)"
        case .staleData(let key, let age):
            return "Data for key '\(key)' is stale (age: \(Int(age)) seconds)"
        case .operationFailure(let operation, let reason):
            return "Storage operation '\(operation)' failed: \(reason)"
        }
    }
} 