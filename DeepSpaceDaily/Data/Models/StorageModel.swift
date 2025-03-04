//
//  StorageModel.swift
//  DeepSpaceDaily
//
//  Created by admin on 29/02/25.
//

import Foundation
import CoreData
import Combine

/// StorageModel serves as a centralized storage manager for the app
/// It coordinates between different specialized storage managers
class StorageModel {
    // MARK: - Singleton
    static let shared = StorageModel()
    
    // MARK: - Storage Managers
    let searchHistory: SearchHistoryManager
    let articleCache: ArticleCacheManager
    let preferences: UserPreferencesManager
    let persistence: PersistenceManager
    
    // MARK: - Cache Cleanup Timer
    private var cacheCleanupTimer: Timer?
    
    // MARK: - Initialization
    
    /// Initialize with default implementations
    private init() {
        let storageAdapter = UserDefaultsAdapter()
        
        self.searchHistory = DefaultSearchHistoryManager(storage: storageAdapter)
        self.articleCache = DefaultArticleCacheManager(storage: storageAdapter)
        self.preferences = DefaultUserPreferencesManager(storage: storageAdapter)
        self.persistence = CoreDataPersistenceManager()
        
        setupCacheCleanupTimer()
    }
    
    /// Initialize with custom managers (useful for testing)
    init(
        searchHistory: SearchHistoryManager,
        articleCache: ArticleCacheManager,
        preferences: UserPreferencesManager,
        persistence: PersistenceManager
    ) {
        self.searchHistory = searchHistory
        self.articleCache = articleCache
        self.preferences = preferences
        self.persistence = persistence
        
        setupCacheCleanupTimer()
    }
    
    // MARK: - Cache Management
    
    private func setupCacheCleanupTimer() {
        // Run cache cleanup every hour
        cacheCleanupTimer = Timer.scheduledTimer(
            withTimeInterval: 3600,
            repeats: true
        ) { [weak self] _ in
            self?.cleanupExpiredCache()
        }
    }
    
    private func cleanupExpiredCache() {
        do {
            // Clean up all content types
            for type in ContentType.allCases {
                if !self.articleCache.isCacheValid(for: type, maxAge: 86400) { // 24 hours
                    try self.articleCache.clearArticleCache(for: type)
                }
            }
        } catch {
            print("Cache cleanup error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Search for articles across all content types
    /// - Parameters:
    ///   - query: The search query
    ///   - contentType: The type of content to search
    /// - Returns: Matching articles or nil if cache is empty
    func searchArticles(query: String, type: ContentType) -> [Article]? {
        guard let articles = try? articleCache.getCachedArticles(type: type, maxAge: 3600) else {
            return nil
        }
        
        let searchTerms = query.lowercased().split(separator: " ")
        return articles.filter { article in
            let title = article.title.lowercased()
            let summary = article.summary.lowercased()
            
            return searchTerms.allSatisfy { term in
                title.contains(term) || summary.contains(term)
            }
        }
    }
    
    /// Get all cached articles for a content type
    /// - Parameter type: The content type
    /// - Returns: Cached articles or nil if not found
    func getCachedArticles(type: ContentType) -> [Article]? {
        return try? articleCache.getCachedArticles(type: type, maxAge: 3600)
    }
    
    /// Save articles to cache
    /// - Parameters:
    ///   - articles: The articles to save
    ///   - type: The content type
    func saveArticles(_ articles: [Article], type: ContentType) {
        try? articleCache.saveArticles(articles, type: type)
    }
    
    /// Save a search query to search history
    /// - Parameter query: The query to save
    func saveSearchQuery(_ query: String) {
        try? searchHistory.saveSearchQuery(query)
    }
    
    /// Get recent searches from search history
    /// - Returns: Array of recent search queries
    func getRecentSearches() -> [String] {
        return (try? searchHistory.getRecentSearches()) ?? []
    }
    
    /// Clear all recent searches
    func clearRecentSearches() {
        try? searchHistory.clearSearchHistory()
    }
    
    /// Clear all data from storage
    func clearAllData() throws {
        // Clear all specialized managers
        try searchHistory.clearSearchHistory()
        try articleCache.clearArticleCache(for: nil) // nil means all types
        
        // Clear Core Data
        try persistence.clearAllEntities()
        
        // Clear UserDefaults completely
        try UserDefaultsAdapter().removeAll()
    }
    
    deinit {
        cacheCleanupTimer?.invalidate()
    }
}

// MARK: - Error Handling
extension StorageModel {
    enum StorageError: Error {
        case saveFailed
        case fetchFailed
        case invalidData
        case cacheExpired
        case searchFailed
        
        var localizedDescription: String {
            switch self {
            case .saveFailed:
                return "Failed to save data"
            case .fetchFailed:
                return "Failed to fetch data"
            case .invalidData:
                return "Invalid data format"
            case .cacheExpired:
                return "Cache has expired"
            case .searchFailed:
                return "Search operation failed"
            }
        }
    }
} 
