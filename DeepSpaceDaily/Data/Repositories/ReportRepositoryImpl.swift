//
//  ReportRepositoryImpl.swift
//  DeepSpaceDaily
//
//  Created by admin on 03/03/25.
//

import Foundation
import Combine

// MARK: - Report Repository Implementation
class ReportRepositoryImpl: ReportRepository {
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
        return getReports(page: page, limit: limit, sortOrder: sortOrder)
            .handleEvents(receiveOutput: { [weak self] articles in
                // Save the loaded articles locally
                self?.saveLastLoadedItems(items: articles)
                print("[ReportRepositoryImpl] Saved \(articles.count) reports from getItems to local storage")
            })
            .eraseToAnyPublisher()
    }
    
    func searchItems(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return searchReports(query: query, page: page, limit: limit, sortOrder: sortOrder)
    }
    
    func getItemsByNewsSite(newsSite: String, page: Int, limit: Int) -> AnyPublisher<[Article], Error> {
        let cacheKey = "reports_site_\(newsSite)_p\(page)_l\(limit)"
        
        // Check in-memory cache first
        if let cachedData = inMemoryCache[cacheKey], 
           Date().timeIntervalSince(cachedData.timestamp) < standardCacheTTL {
            print("[ReportRepositoryImpl] Using in-memory cache for news site: \(newsSite)")
            return Just(cachedData.articles)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        let parameters: [String: Any] = [
            "news_site": newsSite,
            "limit": limit,
            "offset": (page - 1) * limit
        ]
        
        print("[ReportRepositoryImpl] Fetching reports for news site: \(newsSite)")
        
        return apiService.fetch(endpoint: "/reports", parameters: parameters, callerIdentifier: "getItemsByNewsSite")
            .map { (response: ArticleResponse) -> [Article] in
                return response.results
            }
            .handleEvents(receiveOutput: { [weak self] reports in
                // Update in-memory cache
                self?.inMemoryCache[cacheKey] = (articles: reports, timestamp: Date())
                print("[ReportRepositoryImpl] Retrieved \(reports.count) reports for news site: \(newsSite)")
            })
            .mapError { error -> Error in
                return self.mapToDataError(error: error, context: "fetching reports for news site: \(newsSite)")
            }
            .eraseToAnyPublisher()
    }
    
    func saveLastLoadedItems(items: [Article]) {
        do {
            try storageModel.articleCache.saveArticles(items, type: .reports)
        } catch {
            print("[ReportRepositoryImpl] Failed to save last loaded reports: \(error.localizedDescription)")
        }
    }
    
    func getLastLoadedItems() -> [Article]? {
        do {
            return try storageModel.articleCache.getCachedArticles(type: .reports, maxAge: standardCacheTTL)
        } catch {
            print("[ReportRepositoryImpl] Failed to get last loaded reports: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Report-specific methods
    
    func getReports(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        let cacheKey = "reports_p\(page)_l\(limit)_s\(sortOrder.rawValue)"
        
        // First check in-memory cache
        if let cachedData = inMemoryCache[cacheKey], 
           Date().timeIntervalSince(cachedData.timestamp) < standardCacheTTL {
            print("[ReportRepositoryImpl] Using in-memory cache for: \(cacheKey)")
            return Just(cachedData.articles)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Then check storage if this is the first page (most common case)
        if page == 1 {
            do {
                if let cachedReports = try storageModel.articleCache.getCachedArticles(type: .reports, maxAge: standardCacheTTL) {
                    print("[ReportRepositoryImpl] Using storage cache for reports")
                    
                    // Update in-memory cache
                    inMemoryCache[cacheKey] = (articles: cachedReports, timestamp: Date())
                    
                    return Just(cachedReports)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
            } catch let error as StorageError {
                // Log but continue to API request
                print("[ReportRepositoryImpl] Storage error: \(error.localizedDescription), falling back to API")
            } catch {
                print("[ReportRepositoryImpl] Unexpected error: \(error.localizedDescription), falling back to API")
            }
        }
        
        // If no valid cache, fetch from API
        print("[ReportRepositoryImpl] Fetching reports from API with parameters: page=\(page), limit=\(limit), sortOrder=\(sortOrder.rawValue)")
        
        let parameters: [String: Any] = [
            "limit": limit,
            "offset": (page - 1) * limit,
            "ordering": sortOrder == .ascending ? "published_at" : "-published_at"
        ]
        
        return apiService.fetch(endpoint: "/reports", parameters: parameters, callerIdentifier: "getreports")
            .map { (response: ArticleResponse) -> [Article] in
                return response.results
            }
            .handleEvents(receiveOutput: { [weak self] reports in
                guard let self = self else { return }
                
                // Update in-memory cache
                self.inMemoryCache[cacheKey] = (articles: reports, timestamp: Date())
                
                // For first page results, also update storage
                if page == 1 {
                    try? self.storageModel.articleCache.saveArticles(reports, type: .reports)
                }
                
                print("[ReportRepositoryImpl] Retrieved \(reports.count) reports from API")
            })
            .mapError { error -> Error in
                return self.mapToDataError(error: error, context: "fetching reports")
            }
            .eraseToAnyPublisher()
    }
    
    func searchReports(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        let sanitizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitizedQuery.isEmpty else {
            return Fail(error: DataError.validationError(fields: ["query"]))
                .eraseToAnyPublisher()
        }
        
        let cacheKey = "search_reports_\(sanitizedQuery)_p\(page)_l\(limit)_s\(sortOrder.rawValue)"
        
        // Check in-memory cache first for search results
        if let cachedData = inMemoryCache[cacheKey], 
           Date().timeIntervalSince(cachedData.timestamp) < searchCacheTTL {
            print("[ReportRepositoryImpl] Using in-memory cache for search: \(sanitizedQuery)")
            return Just(cachedData.articles)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Try local search for first page requests
        if page == 1 {
            if let localResults = storageModel.searchArticles(query: sanitizedQuery, type: .reports) {
                print("[ReportRepositoryImpl] Using local search for: \(sanitizedQuery)")
                
                // Save search query for history
                try? storageModel.searchHistory.saveSearchQuery(sanitizedQuery)
                
                // Update in-memory cache
                inMemoryCache[cacheKey] = (articles: localResults, timestamp: Date())
                
                return Just(localResults)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
        }
        
        print("[ReportRepositoryImpl] Searching reports via API: \(sanitizedQuery)")
        
        let parameters: [String: Any] = [
            "title_contains": sanitizedQuery,
            "limit": limit,
            "offset": (page - 1) * limit,
            "ordering": sortOrder == .ascending ? "published_at" : "-published_at"
        ]
        
        return apiService.fetch(endpoint: "/reports", parameters: parameters, callerIdentifier: "searchReports")
            .map { (response: ArticleResponse) -> [Article] in
                return response.results
            }
            .handleEvents(receiveOutput: { [weak self] reports in
                guard let self = self else { return }
                
                // Update in-memory cache
                self.inMemoryCache[cacheKey] = (articles: reports, timestamp: Date())
                
                // Save search query for history
                try? self.storageModel.searchHistory.saveSearchQuery(sanitizedQuery)
                
                print("[ReportRepositoryImpl] Retrieved \(reports.count) search results for: \(sanitizedQuery)")
            })
            .mapError { error -> Error in
                return self.mapToDataError(error: error, context: "searching reports for '\(sanitizedQuery)'")
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
    
    func getReports(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        if let site = newsSite {
            return getItemsByNewsSite(newsSite: site, page: 1, limit: 20)
        } else {
            return getReports(page: 1, limit: 20, sortOrder: sortOrder)
        }
    }
    
    func loadMoreReports(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        // Logic to determine next page number based on current results
        let nextPage = determineNextPage(for: .reports)
        
        if let site = newsSite {
            return getItemsByNewsSite(newsSite: site, page: nextPage, limit: 20)
        } else {
            return getReports(page: nextPage, limit: 20, sortOrder: sortOrder)
        }
    }
    
    func refreshReports(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        // Clear in-memory cache for reports to force a fresh fetch
        clearInMemoryCache(for: .reports)
        
        // Fetch fresh data
        if let site = newsSite {
            return getItemsByNewsSite(newsSite: site, page: 1, limit: 20)
        } else {
            return getReports(page: 1, limit: 20, sortOrder: sortOrder)
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
