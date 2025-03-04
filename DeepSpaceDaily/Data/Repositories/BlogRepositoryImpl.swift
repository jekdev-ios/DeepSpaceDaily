//
//  BlogRepositoryImpl.swift
//  DeepSpaceDaily
//
//  Created by admin on 03/03/25.
//

import Foundation
import Combine

// MARK: - Blog Repository Implementation
class BlogRepositoryImpl: BlogRepository {
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
        return getBlogs(page: page, limit: limit, sortOrder: sortOrder)
            .handleEvents(receiveOutput: { [weak self] articles in
                // Save the loaded articles locally
                self?.saveLastLoadedItems(items: articles)
                print("[BlogRepositoryImpl] Saved \(articles.count) blogs from getItems to local storage")
            })
            .eraseToAnyPublisher()
    }

    func searchItems(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return searchBlogs(query: query, page: page, limit: limit, sortOrder: sortOrder)
    }
    
    func getItemsByNewsSite(newsSite: String, page: Int, limit: Int) -> AnyPublisher<[Article], Error> {
        let cacheKey = "blogs_site_\(newsSite)_p\(page)_l\(limit)"
        
        // Check in-memory cache first
        if let cachedData = inMemoryCache[cacheKey], 
           Date().timeIntervalSince(cachedData.timestamp) < standardCacheTTL {
            print("[BlogRepositoryImpl] Using in-memory cache for news site: \(newsSite)")
            return Just(cachedData.articles)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        let parameters: [String: Any] = [
            "news_site": newsSite,
            "limit": limit,
            "offset": (page - 1) * limit
        ]
        
        print("[BlogRepositoryImpl] Fetching blogs for news site: \(newsSite)")
        
        return apiService.fetch(endpoint: "/blogs", parameters: parameters, callerIdentifier: "getitemsbynewssite")
            .map { (response: ArticleResponse) -> [Article] in
                return response.results
            }
            .handleEvents(receiveOutput: { [weak self] blogs in
                // Update in-memory cache
                self?.inMemoryCache[cacheKey] = (articles: blogs, timestamp: Date())
                print("[BlogRepositoryImpl] Retrieved \(blogs.count) blogs for news site: \(newsSite)")
            })
            .mapError { error -> Error in
                return self.mapToDataError(error: error, context: "fetching blogs for news site: \(newsSite)")
            }
            .eraseToAnyPublisher()
    }
    
    func saveLastLoadedItems(items: [Article]) {
        do {
            try storageModel.articleCache.saveArticles(items, type: .blogs)
        } catch {
            print("[BlogRepositoryImpl] Failed to save last loaded blogs: \(error.localizedDescription)")
        }
    }
    
    func getLastLoadedItems() -> [Article]? {
        do {
            return try storageModel.articleCache.getCachedArticles(type: .blogs, maxAge: standardCacheTTL)
        } catch {
            print("[BlogRepositoryImpl] Failed to get last loaded blogs: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Blog-specific methods
    
    func getBlogs(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        let cacheKey = "blogs_p\(page)_l\(limit)_s\(sortOrder.rawValue)"
        
        // First check in-memory cache
        if let cachedData = inMemoryCache[cacheKey], 
           Date().timeIntervalSince(cachedData.timestamp) < standardCacheTTL {
            print("[BlogRepositoryImpl] Using in-memory cache for: \(cacheKey)")
            return Just(cachedData.articles)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Then check storage if this is the first page (most common case)
        if page == 1 {
            do {
                if let cachedBlogs = try storageModel.articleCache.getCachedArticles(type: .blogs, maxAge: standardCacheTTL) {
                    print("[BlogRepositoryImpl] Using storage cache for blogs")
                    
                    // Update in-memory cache
                    inMemoryCache[cacheKey] = (articles: cachedBlogs, timestamp: Date())
                    
                    return Just(cachedBlogs)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
            } catch let error as StorageError {
                // Log but continue to API request
                print("[BlogRepositoryImpl] Storage error: \(error.localizedDescription), falling back to API")
            } catch {
                print("[BlogRepositoryImpl] Unexpected error: \(error.localizedDescription), falling back to API")
            }
        }
        
        // If no valid cache, fetch from API
        print("[BlogRepositoryImpl] Fetching blogs from API with parameters: page=\(page), limit=\(limit), sortOrder=\(sortOrder.rawValue)")
        
        let parameters: [String: Any] = [
            "limit": limit,
            "offset": (page - 1) * limit,
            "ordering": sortOrder == .ascending ? "published_at" : "-published_at"
        ]
        
        return apiService.fetch(endpoint: "/blogs", parameters: parameters, callerIdentifier: "getblogs")
            .map { (response: ArticleResponse) -> [Article] in
                return response.results
            }
            .handleEvents(receiveOutput: { [weak self] blogs in
                guard let self = self else { return }
                
                // Update in-memory cache
                self.inMemoryCache[cacheKey] = (articles: blogs, timestamp: Date())
                
                // For first page results, also update storage
                if page == 1 {
                    try? self.storageModel.articleCache.saveArticles(blogs, type: .blogs)
                }
                
                print("[BlogRepositoryImpl] Retrieved \(blogs.count) blogs from API")
            })
            .mapError { error -> Error in
                return self.mapToDataError(error: error, context: "fetching blogs")
            }
            .eraseToAnyPublisher()
    }
    
    func searchBlogs(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        let sanitizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitizedQuery.isEmpty else {
            return Fail(error: DataError.validationError(fields: ["query"]))
                .eraseToAnyPublisher()
        }
        
        let cacheKey = "search_blogs_\(sanitizedQuery)_p\(page)_l\(limit)_s\(sortOrder.rawValue)"
        
        // Check in-memory cache first for search results
        if let cachedData = inMemoryCache[cacheKey], 
           Date().timeIntervalSince(cachedData.timestamp) < searchCacheTTL {
            print("[BlogRepositoryImpl] Using in-memory cache for search: \(sanitizedQuery)")
            return Just(cachedData.articles)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Try local search for first page requests
        if page == 1 {
            if let localResults = storageModel.searchArticles(query: sanitizedQuery, type: .blogs) {
                print("[BlogRepositoryImpl] Using local search for: \(sanitizedQuery)")
                
                // Save search query for history
                try? storageModel.searchHistory.saveSearchQuery(sanitizedQuery)
                
                // Update in-memory cache
                inMemoryCache[cacheKey] = (articles: localResults, timestamp: Date())
                
                return Just(localResults)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
        }
        
        print("[BlogRepositoryImpl] Searching blogs via API: \(sanitizedQuery)")
        
        let parameters: [String: Any] = [
            "title_contains": sanitizedQuery,
            "limit": limit,
            "offset": (page - 1) * limit,
            "ordering": sortOrder == .ascending ? "published_at" : "-published_at"
        ]
        
        return apiService.fetch(endpoint: "/blogs", parameters: parameters, callerIdentifier: "searchBlogs")
            .map { (response: ArticleResponse) -> [Article] in
                return response.results
            }
            .handleEvents(receiveOutput: { [weak self] blogs in
                guard let self = self else { return }
                
                // Update in-memory cache
                self.inMemoryCache[cacheKey] = (articles: blogs, timestamp: Date())
                
                // Save search query for history
                try? self.storageModel.searchHistory.saveSearchQuery(sanitizedQuery)
                
                print("[BlogRepositoryImpl] Retrieved \(blogs.count) search results for: \(sanitizedQuery)")
            })
            .mapError { error -> Error in
                return self.mapToDataError(error: error, context: "searching blogs for '\(sanitizedQuery)'")
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
    
    func getBlogs(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        if let site = newsSite {
            return getItemsByNewsSite(newsSite: site, page: 1, limit: 20)
        } else {
            return getBlogs(page: 1, limit: 20, sortOrder: sortOrder)
        }
    }
    
    func loadMoreBlogs(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        // Logic to determine next page number based on current results
        let nextPage = determineNextPage(for: .blogs)
        
        if let site = newsSite {
            return getItemsByNewsSite(newsSite: site, page: nextPage, limit: 20)
        } else {
            return getBlogs(page: nextPage, limit: 20, sortOrder: sortOrder)
        }
    }
    
    func refreshBlogs(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        // Clear in-memory cache for blogs to force a fresh fetch
        clearInMemoryCache(for: .blogs)
        
        // Fetch fresh data
        if let site = newsSite {
            return getItemsByNewsSite(newsSite: site, page: 1, limit: 20)
        } else {
            return getBlogs(page: 1, limit: 20, sortOrder: sortOrder)
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
