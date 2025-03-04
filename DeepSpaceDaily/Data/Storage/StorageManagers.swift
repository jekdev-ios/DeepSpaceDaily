//
//  StorageManagers.swift
//  DeepSpaceDaily
//
//  Created by admin on 03/03/25.
//

import Foundation
import Combine

// MARK: - Search History Manager

/// Protocol for managing search history
protocol SearchHistoryManager {
    /// Save a search query
    /// - Parameter query: The query to save
    func saveSearchQuery(_ query: String) throws
    
    /// Get recent searches
    /// - Returns: Array of recent search queries
    func getRecentSearches() throws -> [String]
    
    /// Clear search history
    func clearSearchHistory() throws
    
    /// Publisher for search history updates
    var searchUpdates: AnyPublisher<[String], Never> { get }
}

/// Default implementation of SearchHistoryManager
class DefaultSearchHistoryManager: SearchHistoryManager {
    private let storage: StorageAdapter
    private let searchHistoryKey = "recentSearches"
    private let maxEntries: Int
    private let searchSubject = PassthroughSubject<[String], Never>()
    
    init(storage: StorageAdapter, maxEntries: Int = 10) {
        self.storage = storage
        self.maxEntries = maxEntries
    }
    
    var searchUpdates: AnyPublisher<[String], Never> {
        return searchSubject.eraseToAnyPublisher()
    }
    
    func saveSearchQuery(_ query: String) throws {
        // Trim and validate query
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }
        
        // Get existing searches
        var searches = try getRecentSearches()
        
        // Remove if already exists (to move it to the top)
        searches.removeAll { $0.lowercased() == trimmedQuery.lowercased() }
        
        // Add to the beginning
        searches.insert(trimmedQuery, at: 0)
        
        // Limit to max entries
        if searches.count > maxEntries {
            searches = Array(searches.prefix(maxEntries))
        }
        
        // Save and notify
        try storage.save(value: searches, forKey: searchHistoryKey)
        searchSubject.send(searches)
    }
    
    func getRecentSearches() throws -> [String] {
        return try storage.load(forKey: searchHistoryKey) ?? []
    }
    
    func clearSearchHistory() throws {
        try storage.remove(forKey: searchHistoryKey)
        searchSubject.send([])
    }
}

// MARK: - Article Cache Manager

/// Protocol for managing article caching
protocol ArticleCacheManager {
    /// Save articles to cache
    /// - Parameters:
    ///   - articles: The articles to cache
    ///   - type: Content type
    func saveArticles(_ articles: [Article], type: ContentType) throws
    
    /// Get cached articles
    /// - Parameters:
    ///   - type: Content type
    ///   - maxAge: Maximum age in seconds
    /// - Returns: Cached articles or nil if not found/expired
    func getCachedArticles(type: ContentType, maxAge: TimeInterval) throws -> [Article]?
    
    /// Clear article cache
    /// - Parameter type: Content type (nil for all types)
    func clearArticleCache(for type: ContentType?) throws
    
    /// Check if cache is valid
    /// - Parameters:
    ///   - type: Content type
    ///   - maxAge: Maximum age in seconds
    /// - Returns: True if cache exists and is valid
    func isCacheValid(for type: ContentType, maxAge: TimeInterval) -> Bool
}

/// Default implementation of ArticleCacheManager
class DefaultArticleCacheManager: ArticleCacheManager {
    private let storage: StorageAdapter
    private let cacheKeyPrefix = "articleCache_"
    
    init(storage: StorageAdapter) {
        self.storage = storage
    }
    
    func saveArticles(_ articles: [Article], type: ContentType) throws {
        let wrapper = StorageWrapper(data: articles)
        let key = cacheKey(for: type)
        try storage.save(value: wrapper, forKey: key)
    }
    
    func getCachedArticles(type: ContentType, maxAge: TimeInterval = 3600) throws -> [Article]? {
        let key = cacheKey(for: type)
        
        guard let wrapper: StorageWrapper<[Article]> = try storage.load(forKey: key) else {
            return nil
        }
        
        if !wrapper.isValid(ttl: maxAge) {
            throw StorageError.staleData(key: key, age: wrapper.age)
        }
        
        return wrapper.data
    }
    
    func clearArticleCache(for type: ContentType?) throws {
        if let specificType = type {
            try storage.remove(forKey: cacheKey(for: specificType))
        } else {
            // Clear all content types
            for type in ContentType.allCases {
                try storage.remove(forKey: cacheKey(for: type))
            }
        }
    }
    
    func isCacheValid(for type: ContentType, maxAge: TimeInterval = 3600) -> Bool {
        let key = cacheKey(for: type)
        
        do {
            guard let wrapper: StorageWrapper<[Article]> = try storage.load(forKey: key) else {
                return false
            }
            return wrapper.isValid(ttl: maxAge)
        } catch {
            return false
        }
    }
    
    private func cacheKey(for type: ContentType) -> String {
        return "\(cacheKeyPrefix)\(type.rawValue)"
    }
}

// MARK: - User Preferences Manager

/// Protocol for managing user preferences
protocol UserPreferencesManager {
    /// Save a preference
    /// - Parameters:
    ///   - value: The value to save
    ///   - key: Preference key
    func savePreference<T: Codable>(_ value: T, forKey key: String) throws
    
    /// Get a preference
    /// - Parameter key: Preference key
    /// - Returns: The preference value or nil if not found
    func getPreference<T: Codable>(forKey key: String) throws -> T?
    
    /// Remove a preference
    /// - Parameter key: Preference key
    func removePreference(forKey key: String) throws
}

/// Default implementation of UserPreferencesManager
class DefaultUserPreferencesManager: UserPreferencesManager {
    private let storage: StorageAdapter
    private let prefKeyPrefix = "pref_"
    
    init(storage: StorageAdapter) {
        self.storage = storage
    }
    
    func savePreference<T: Codable>(_ value: T, forKey key: String) throws {
        try storage.save(value: value, forKey: prefKey(for: key))
    }
    
    func getPreference<T: Codable>(forKey key: String) throws -> T? {
        return try storage.load(forKey: prefKey(for: key))
    }
    
    func removePreference(forKey key: String) throws {
        try storage.remove(forKey: prefKey(for: key))
    }
    
    private func prefKey(for key: String) -> String {
        return "\(prefKeyPrefix)\(key)"
    }
}

// MARK: - Persistence Manager

/// Protocol for managing Core Data persistence
protocol PersistenceManager {
    /// Save changes to persistence
    func saveContext() throws
    
    /// Clear all Core Data entities
    func clearAllEntities() throws
    
    /// Get the managed object context
    var viewContext: NSManagedObjectContext { get }
}

import CoreData

/// Default implementation of PersistenceManager using Core Data
class CoreDataPersistenceManager: PersistenceManager {
    private let persistenceController: PersistenceController
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    var viewContext: NSManagedObjectContext {
        return persistenceController.container.viewContext
    }
    
    func saveContext() throws {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                throw StorageError.operationFailure(
                    operation: "saveContext",
                    reason: error.localizedDescription
                )
            }
        }
    }
    
    func clearAllEntities() throws {
        let entities = persistenceController.container.managedObjectModel.entities
        
        for entity in entities {
            if let entityName = entity.name {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                
                do {
                    try viewContext.execute(batchDeleteRequest)
                } catch {
                    throw StorageError.operationFailure(
                        operation: "clearEntity_\(entityName)",
                        reason: error.localizedDescription
                    )
                }
            }
        }
        
        try saveContext()
    }
} 