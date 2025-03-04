import Foundation

/// SSL Validation Mode for API requests
public enum SSLValidationMode: String, CaseIterable {
    /// Strict validation with certificate pinning
    case strict
    
    /// Standard validation using system trust store
    case standard
    
    /// No validation (insecure, use only for development/testing)
    case disabled
} 