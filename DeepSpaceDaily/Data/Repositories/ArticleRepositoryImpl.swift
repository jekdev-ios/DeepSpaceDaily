//
//  ArticleRepositoryImpl.swift
//  DeepSpaceDaily
//
//  Created by admin on 28/02/25.
//

import Foundation
import Combine

// MARK: - Article Repository Implementation
class ArticleRepositoryImpl: ArticleRepository {
    private let apiService: APIService
    private let storageModel: StorageModel
    
    // Cache TTL values
    private let standardCacheTTL: TimeInterval = 3600 // 1 hour for standard requests
    private let searchCacheTTL: TimeInterval = 1800   // 30 minutes for search results
    
    // In-memory cache for faster access
    private var inMemoryCache: [String: (articles: [Article], timestamp: Date)] = [:]
    
    init(apiService: APIService, storageModel: StorageModel = .shared) {
        self.apiService = apiService
        self.storageModel = storageModel
    }
    
    // MARK: - ContentRepository Protocol Implementation
    
    func getItems(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return getArticles(page: page, limit: limit, sortOrder: sortOrder)
            .handleEvents(receiveOutput: { [weak self] articles in
                // Save the loaded articles locally
                self?.saveLastLoadedItems(items: articles)
                print("[ArticleRepositoryImpl] Saved \(articles.count) articles from getItems to local storage")
            })
            .eraseToAnyPublisher()
    }
    
    func searchItems(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return searchArticles(query: query, page: page, limit: limit, sortOrder: sortOrder)
    }
    
    func getItemsByNewsSite(newsSite: String, page: Int, limit: Int) -> AnyPublisher<[Article], Error> {
        let cacheKey = "articles_site_\(newsSite)_p\(page)_l\(limit)"
        
        // Check in-memory cache first
        if let cachedData = inMemoryCache[cacheKey], 
           Date().timeIntervalSince(cachedData.timestamp) < standardCacheTTL {
            print("[ArticleRepositoryImpl] Using in-memory cache for news site: \(newsSite)")
            return Just(cachedData.articles)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        let parameters: [String: Any] = [
            "news_site": newsSite,
            "limit": limit,
            "offset": (page - 1) * limit
        ]
        
        print("[ArticleRepositoryImpl] Fetching articles for news site: \(newsSite)")
        
        return apiService.fetch(
            endpoint: "/articles", 
            parameters: parameters,
            callerIdentifier: "ArticleRepositoryImpl.getArticlesByNewsSite"
        )
            .map { (response: ArticleResponse) -> [Article] in
                return response.results
            }
            .handleEvents(receiveOutput: { [weak self] articles in
                // Update in-memory cache
                self?.inMemoryCache[cacheKey] = (articles: articles, timestamp: Date())
                print("[ArticleRepositoryImpl] Retrieved \(articles.count) articles for news site: \(newsSite)")
            })
            .mapError { error -> Error in
                return self.mapToDataError(error: error, context: "fetching articles for news site: \(newsSite)")
            }
            .eraseToAnyPublisher()
    }
    
    func saveLastLoadedItems(items: [Article]) {
        do {
            try storageModel.articleCache.saveArticles(items, type: .articles)
        } catch {
            print("[ArticleRepositoryImpl] Failed to save last loaded articles: \(error.localizedDescription)")
        }
    }
    
    func getLastLoadedItems() -> [Article]? {
        do {
            return try storageModel.articleCache.getCachedArticles(type: .articles, maxAge: standardCacheTTL)
        } catch {
            print("[ArticleRepositoryImpl] Failed to get last loaded articles: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - ArticleRepository Protocol Implementation
    
    func getArticles(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        let cacheKey = "articles_p\(page)_l\(limit)_s\(sortOrder.rawValue)"
        
        // First check in-memory cache
        if let cachedData = inMemoryCache[cacheKey], 
           Date().timeIntervalSince(cachedData.timestamp) < standardCacheTTL {
            print("[ArticleRepositoryImpl] Using in-memory cache for: \(cacheKey)")
            return Just(cachedData.articles)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Then check storage if this is the first page (most common case)
        if page == 1 {
            do {
                if let cachedArticles = try storageModel.articleCache.getCachedArticles(type: .articles, maxAge: standardCacheTTL) {
                    print("[ArticleRepositoryImpl] Using storage cache for articles")
                    
                    // Update in-memory cache
                    inMemoryCache[cacheKey] = (articles: cachedArticles, timestamp: Date())
                    
                    return Just(cachedArticles)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
            } catch let error as StorageError {
                // Log but continue to API request
                print("[ArticleRepositoryImpl] Storage error: \(error.localizedDescription), falling back to API")
            } catch {
                print("[ArticleRepositoryImpl] Unexpected error: \(error.localizedDescription), falling back to API")
            }
        }
        
        // If no valid cache, fetch from API
        print("[ArticleRepositoryImpl] Fetching articles from API with parameters: page=\(page), limit=\(limit), sortOrder=\(sortOrder.rawValue)")
        
        let parameters: [String: Any] = [
            "limit": limit,
            "offset": (page - 1) * limit,
            "ordering": sortOrder == .ascending ? "published_at" : "-published_at"
        ]
        
        return apiService.fetch(
            endpoint: "/articles", 
            parameters: parameters,
            callerIdentifier: "ArticleRepositoryImpl.getArticles"
        )
            .map { (response: ArticleResponse) -> [Article] in
                return response.results
            }
            .handleEvents(receiveOutput: { [weak self] articles in
                guard let self = self else { return }
                
                // Update in-memory cache
                self.inMemoryCache[cacheKey] = (articles: articles, timestamp: Date())
                
                // For first page results, also update storage
                if page == 1 {
                    try? self.storageModel.articleCache.saveArticles(articles, type: .articles)
                }
                
                print("[ArticleRepositoryImpl] Retrieved \(articles.count) articles from API")
            })
            .mapError { error -> Error in
                return self.mapToDataError(error: error, context: "fetching articles")
            }
            .eraseToAnyPublisher()
    }
    
    func searchArticles(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        let sanitizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitizedQuery.isEmpty else {
            return Fail(error: DataError.validationError(fields: ["query"]))
                .eraseToAnyPublisher()
        }
        
        let cacheKey = "search_\(sanitizedQuery)_p\(page)_l\(limit)_s\(sortOrder.rawValue)"
        
        // Check in-memory cache first
        if let cachedData = inMemoryCache[cacheKey],
           Date().timeIntervalSince(cachedData.timestamp) < searchCacheTTL {
            print("[ArticleRepositoryImpl] Using in-memory cache for search: \(sanitizedQuery)")
            return Just(cachedData.articles)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Try local search for first page requests
        if page == 1 {
            if let localResults = storageModel.searchArticles(query: sanitizedQuery, type: .articles) {
                print("[ArticleRepositoryImpl] Using local search for: \(sanitizedQuery)")
                
                // Save search query for history
                try? storageModel.searchHistory.saveSearchQuery(sanitizedQuery)
                
                // Update in-memory cache
                inMemoryCache[cacheKey] = (articles: localResults, timestamp: Date())
                
                return Just(localResults)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
        }
        
        // If no cached results, search via API
        print("[ArticleRepositoryImpl] Searching articles via API: \(sanitizedQuery)")
        
        let parameters: [String: Any] = [
            "title_contains": sanitizedQuery,
            "limit": limit,
            "offset": (page - 1) * limit,
            "ordering": sortOrder == .ascending ? "published_at" : "-published_at"
        ]
        
        return apiService.fetch(
            endpoint: "/articles", 
            parameters: parameters,
            callerIdentifier: "ArticleRepositoryImpl.searchArticles"
        )
            .map { (response: ArticleResponse) -> [Article] in
                return response.results
            }
            .handleEvents(receiveOutput: { [weak self] articles in
                guard let self = self else { return }
                
                // Update in-memory cache
                self.inMemoryCache[cacheKey] = (articles: articles, timestamp: Date())
                
                // Save search query for history
                try? self.storageModel.searchHistory.saveSearchQuery(sanitizedQuery)
                
                print("[ArticleRepositoryImpl] Retrieved \(articles.count) search results for: \(sanitizedQuery)")
            })
            .mapError { error -> Error in
                return self.mapToDataError(error: error, context: "searching articles for '\(sanitizedQuery)'")
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Helper Methods
    
    private func mapToDataError(error: Error, context: String) -> Error {
        if let apiError = error as? APIError {
            switch apiError {
            case .requestFailed(let urlError):
                return DataError.networkError(underlying: urlError)
            case .serverError(let statusCode):
                return DataError.serverError(statusCode: statusCode, message: "Server returned error code: \(statusCode)")
            case .decodingFailed(let decodingError):
                return DataError.serializationError(message: "Failed to decode response: \(decodingError.localizedDescription)")
            case .invalidResponse:
                return DataError.serverError(statusCode: 0, message: "Invalid server response")
            case .invalidURL:
                return DataError.clientError(message: "Invalid URL")
            case .unknown:
                return DataError.unknown(message: "Unknown API error")
            }
        } else if let storageError = error as? StorageError {
            switch storageError {
            case .staleData(let key, let age):
                return DataError.staleData(age: age)
            case .serializationFailure(_, let underlyingError):
                return DataError.serializationError(message: underlyingError.localizedDescription)
            default:
                return DataError.cacheError(reason: storageError.localizedDescription)
            }
        }
        
        return DataError.unknown(message: "Error \(context): \(error.localizedDescription)")
    }
    
    // MARK: - Additional Repository Methods
    
    func getArticles(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        if let site = newsSite {
            return getItemsByNewsSite(newsSite: site, page: 1, limit: 20)
        } else {
            return getArticles(page: 1, limit: 20, sortOrder: sortOrder)
        }
    }
    
    func loadMoreArticles(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        // Logic to determine next page number based on current results
        let nextPage = determineNextPage(for: .articles)
        
        if let site = newsSite {
            return getItemsByNewsSite(newsSite: site, page: nextPage, limit: 20)
        } else {
            return getArticles(page: nextPage, limit: 20, sortOrder: sortOrder)
        }
    }
    
    func refreshArticles(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        // Clear in-memory cache for articles to force a fresh fetch
        clearInMemoryCache(for: .articles)
        
        // Fetch fresh data
        if let site = newsSite {
            return getItemsByNewsSite(newsSite: site, page: 1, limit: 20)
        } else {
            return getArticles(page: 1, limit: 20, sortOrder: sortOrder)
        }
    }
    
    private func determineNextPage(for contentType: ContentType) -> Int {
        // Logic to calculate next page based on current cached data
        let currentCount = getLastLoadedItems()?.count ?? 0
        return (currentCount / 20) + 1
    }
    
    private func clearInMemoryCache(for contentType: ContentType) {
        // Remove all keys related to this content type
        let keysToRemove = inMemoryCache.keys.filter { $0.hasPrefix(contentType.rawValue) }
        keysToRemove.forEach { inMemoryCache.removeValue(forKey: $0) }
    }
}
