//
//  DataError.swift
//  DeepSpaceDaily
//
//  Created by admin on 03/03/25.
//

import Foundation

/// Domain-specific error hierarchy for the data layer
enum DataError: Error {
    case networkError(underlying: Error)
    case serializationError(message: String)
    case cacheError(reason: String)
    case notFound(entityType: String, identifier: String?)
    case staleData(age: TimeInterval)
    case validationError(fields: [String])
    case unauthorized
    case serverError(statusCode: Int, message: String?)
    case clientError(message: String)
    case unknown(message: String)
}

extension DataError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serializationError(let message):
            return "Failed to process data: \(message)"
        case .cacheError(let reason):
            return "Cache error: \(reason)"
        case .notFound(let entityType, let identifier):
            if let id = identifier {
                return "\(entityType) with ID \(id) not found"
            } else {
                return "\(entityType) not found"
            }
        case .staleData(let age):
            return "Data is outdated (age: \(Int(age)) seconds)"
        case .validationError(let fields):
            return "Validation failed for fields: \(fields.joined(separator: ", "))"
        case .unauthorized:
            return "Authentication required to access this resource"
        case .serverError(let statusCode, let message):
            if let errorMessage = message {
                return "Server error (\(statusCode)): \(errorMessage)"
            } else {
                return "Server error with status code: \(statusCode)"
            }
        case .clientError(let message):
            return "Client-side error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
} 