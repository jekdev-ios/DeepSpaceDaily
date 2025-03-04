//
//  MockDependencyContainer.swift
//  DeepSpaceDaily
//
//  Created by admin on 03/03/25.
//

import Foundation
import Combine
import Auth0
import CoreData

/// Mock implementation of DependencyContainer for testing
class MockDependencyContainer: DependencyContainer {
    // MARK: - Services
    var apiService: APIService = MockAPIService()
    var storageModel: StorageModel = MockStorageModel()
    
    // MARK: - Repositories
    var articleRepository: any ArticleRepository = MockArticleRepository()
    var blogRepository: any BlogRepository = MockBlogRepository()
    var reportRepository: any ReportRepository = MockReportRepository()
    var newsSiteRepository: any NewsSiteRepository = MockNewsSiteRepository()
    var searchRepository: any SearchRepository = MockSearchRepository()
    var authRepository: any AuthRepository = MockAuthRepository()
    
    // MARK: - Use Cases
    lazy var contentLoadingUseCase: ContentLoadingUseCase = MockContentLoadingUseCase()
    lazy var getArticlesUseCase: GetArticlesUseCase = MockGetArticlesUseCase()
    lazy var searchArticlesUseCase: SearchArticlesUseCase = MockSearchArticlesUseCase()
    lazy var getNewsSitesUseCase: GetNewsSitesUseCase = MockGetNewsSitesUseCase()
    lazy var saveRecentSearchUseCase: SaveRecentSearchUseCase = MockSaveRecentSearchUseCase()
    lazy var getRecentSearchesUseCase: GetRecentSearchesUseCase = MockGetRecentSearchesUseCase()
    lazy var clearRecentSearchesUseCase: ClearRecentSearchesUseCase = MockClearRecentSearchesUseCase()
    lazy var saveLastLoadedArticlesUseCase: SaveLastLoadedArticlesUseCase = MockSaveLastLoadedArticlesUseCase()
    lazy var getLastLoadedArticlesUseCase: GetLastLoadedArticlesUseCase = MockGetLastLoadedArticlesUseCase()
    lazy var getBlogsUseCase: GetBlogsUseCase = MockGetBlogsUseCase()
    lazy var searchBlogsUseCase: SearchBlogsUseCase = MockSearchBlogsUseCase()
    lazy var saveLastLoadedBlogsUseCase: SaveLastLoadedBlogsUseCase = MockSaveLastLoadedBlogsUseCase()
    lazy var getLastLoadedBlogsUseCase: GetLastLoadedBlogsUseCase = MockGetLastLoadedBlogsUseCase()
    lazy var getReportsUseCase: GetReportsUseCase = MockGetReportsUseCase()
    lazy var searchReportsUseCase: SearchReportsUseCase = MockSearchReportsUseCase()
    lazy var saveLastLoadedReportsUseCase: SaveLastLoadedReportsUseCase = MockSaveLastLoadedReportsUseCase()
    lazy var getLastLoadedReportsUseCase: GetLastLoadedReportsUseCase = MockGetLastLoadedReportsUseCase()
    lazy var loginUseCase: LoginUseCase = MockLoginUseCase()
    lazy var logoutUseCase: LogoutUseCase = MockLogoutUseCase()
    lazy var getCurrentUserUseCase: GetCurrentUserUseCase = MockGetCurrentUserUseCase()
    lazy var isLoggedInUseCase: IsLoggedInUseCase = MockIsLoggedInUseCase()
    lazy var manageSessionUseCase: ManageSessionUseCase = MockManageSessionUseCase()
    
    init() {
        // Initialize with default mock implementations
    }
}

// MARK: - Mock Implementations

// These are implementations with mock logic for testing
class MockAPIService: APIService {
    override func fetch<T: Decodable>(endpoint: String, parameters: [String: Any], callerIdentifier: String) -> AnyPublisher<T, APIError> {
        return Fail(error: APIError.unknown).eraseToAnyPublisher()
    }
}

class MockStorageModel: StorageModel {
    // Mock implementation of StorageModel for testing
    init() {
        // Call super.init() with custom mock managers
        super.init(
            searchHistory: MockSearchHistoryManager(),
            articleCache: MockArticleCacheManager(),
            preferences: MockUserPreferencesManager(),
            persistence: MockPersistenceManager()
        )
    }
    
    class MockSearchHistoryManager: SearchHistoryManager {
        private var searches: [String] = []
        private let searchHistoryPublisher = PassthroughSubject<[String], Never>()
        
        var searchUpdates: AnyPublisher<[String], Never> {
            return searchHistoryPublisher.eraseToAnyPublisher()
        }
        
        func saveSearchQuery(_ query: String) throws {
            searches.append(query)
            if searches.count > 10 {
                searches.removeFirst()
            }
            searchHistoryPublisher.send(searches)
        }
        
        func getRecentSearches() throws -> [String] {
            return searches
        }
        
        func clearSearchHistory() throws {
            searches.removeAll()
            searchHistoryPublisher.send(searches)
        }
    }
    
    class MockArticleCacheManager: ArticleCacheManager {
        private var articles: [String: [Article]] = [:]
        private var timestamps: [String: Date] = [:]
        
        func saveArticles(_ articles: [Article], type: ContentType) throws {
            self.articles[type.rawValue] = articles
            self.timestamps[type.rawValue] = Date()
        }
        
        func getCachedArticles(type: ContentType, maxAge: TimeInterval = 3600) throws -> [Article]? {
            guard let articles = self.articles[type.rawValue],
                  let timestamp = self.timestamps[type.rawValue] else {
                return nil
            }
            
            let age = Date().timeIntervalSince(timestamp)
            if age > maxAge {
                throw NSError(domain: "MockArticleCacheManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cache expired"])
            }
            
            return articles
        }
        
        func clearArticleCache(for type: ContentType?) throws {
            if let type = type {
                articles.removeValue(forKey: type.rawValue)
                timestamps.removeValue(forKey: type.rawValue)
            } else {
                articles.removeAll()
                timestamps.removeAll()
            }
        }
        
        func isCacheValid(for type: ContentType, maxAge: TimeInterval = 3600) -> Bool {
            guard let timestamp = timestamps[type.rawValue] else {
                return false
            }
            
            let age = Date().timeIntervalSince(timestamp)
            return age <= maxAge
        }
    }
    
    class MockUserPreferencesManager: UserPreferencesManager {
        private var preferences: [String: Any] = [:]
        
        func savePreference<T: Codable>(_ value: T, forKey key: String) throws {
            preferences[key] = value
        }
        
        func getPreference<T: Codable>(forKey key: String) throws -> T? {
            return preferences[key] as? T
        }
        
        func removePreference(forKey key: String) throws {
            preferences.removeValue(forKey: key)
        }
    }
    
    class MockPersistenceManager: PersistenceManager {
        lazy var viewContext: NSManagedObjectContext = {
            // Return an in-memory context for testing
            let container = NSPersistentContainer(name: "DeepSpaceDaily")
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
            container.loadPersistentStores { (_, error) in
                if let error = error {
                    fatalError("Failed to load in-memory store: \(error)")
                }
            }
            return container.viewContext
        }()
        
        func saveContext() throws {
            // Mock implementation - no-op
            if viewContext.hasChanges {
                try viewContext.save()
            }
        }
        
        func clearAllEntities() throws {
            // Mock implementation - no-op
        }
    }
    
    override func searchArticles(query: String, type: ContentType) -> [Article]? {
        guard let articleManager = self.articleCache as? MockArticleCacheManager,
              let articles = try? articleManager.getCachedArticles(type: type) else {
            return []
        }
        
        // Simple search implementation
        let searchTerms = query.lowercased().split(separator: " ")
        return articles.filter { article in
            let title = article.title.lowercased()
            let summary = article.summary.lowercased()
            
            return searchTerms.allSatisfy { term in
                title.contains(term) || summary.contains(term)
            }
        }
    }
}

class MockArticleRepository: ArticleRepository {
    typealias Item = Article
    
    private var articles: [Article] = []
    
    func getItems(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just(articles).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func searchItems(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just(articles).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func getItemsByNewsSite(newsSite: String, page: Int, limit: Int) -> AnyPublisher<[Article], Error> {
        return Just(articles).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func saveLastLoadedItems(items: [Article]) {
        self.articles = items
    }
    
    func getLastLoadedItems() -> [Article]? {
        return articles
    }
    
    func getArticles(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just(articles).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func searchArticles(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just(articles).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func getArticles(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just(articles).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func loadMoreArticles(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just(articles).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func refreshArticles(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just(articles).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

class MockBlogRepository: BlogRepository {
    typealias Item = Article
    
    private var blogs: [Article] = []
    
    func getItems(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just(blogs).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func searchItems(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just(blogs).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func getItemsByNewsSite(newsSite: String, page: Int, limit: Int) -> AnyPublisher<[Article], Error> {
        return Just(blogs).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func saveLastLoadedItems(items: [Article]) {
        self.blogs = items
    }
    
    func getLastLoadedItems() -> [Article]? {
        return blogs
    }
    
    func getBlogs(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just(blogs).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func searchBlogs(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just(blogs).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func getBlogs(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just(blogs).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func loadMoreBlogs(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just(blogs).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func refreshBlogs(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just(blogs).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

class MockReportRepository: ReportRepository {
    typealias Item = Article
    
    private var reports: [Article] = []
    
    func getItems(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just(reports).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func searchItems(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just(reports).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func getItemsByNewsSite(newsSite: String, page: Int, limit: Int) -> AnyPublisher<[Article], Error> {
        return Just(reports).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func saveLastLoadedItems(items: [Article]) {
        self.reports = items
    }
    
    func getLastLoadedItems() -> [Article]? {
        return reports
    }
    
    func getReports(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just(reports).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func searchReports(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just(reports).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func getReports(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just(reports).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func loadMoreReports(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just(reports).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func refreshReports(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just(reports).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

class MockNewsSiteRepository: NewsSiteRepository {
    func getNewsSites(contentType: ContentType) -> AnyPublisher<[String], Error> {
        return Just(["SpaceNews", "NASA", "SpaceX"]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

class MockSearchRepository: SearchRepository {
    private var searches: [String] = []
    
    func saveRecentSearch(query: String) {
        searches.append(query)
    }
    
    func getRecentSearches() -> [String] {
        return searches
    }
    
    func clearRecentSearches() {
        searches.removeAll()
    }
}

class MockAuthRepository: AuthRepository {
    private var currentUser: User = User.guest
    private var loggedIn: Bool = false
    
    func login(credentials: Credentials?) -> AnyPublisher<User, AuthError> {
        loggedIn = true
        currentUser = User(id: "mock-id", name: "Mock User", email: "mock@example.com", emailVerified: "true", picture: nil, updatedAt: nil)
        return Just(currentUser).setFailureType(to: AuthError.self).eraseToAnyPublisher()
    }
    
    func logout() -> AnyPublisher<Void, AuthError> {
        loggedIn = false
        currentUser = User.guest
        return Just(()).setFailureType(to: AuthError.self).eraseToAnyPublisher()
    }
    
    func getCurrentUser() -> User {
        return currentUser
    }
    
    func isLoggedIn() -> Bool {
        return loggedIn
    }
    
    func startSessionTimer() {
        // No-op for mock
    }
    
    func resetSessionTimer() {
        // No-op for mock
    }
    
    func stopSessionTimer() {
        // No-op for mock
    }
}

class MockContentLoadingUseCase: ContentLoadingUseCase {
    func loadContent(for contentType: ContentType, newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func loadMoreContent(for contentType: ContentType, newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func refreshContent(for contentType: ContentType, newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

class MockGetArticlesUseCase: GetArticlesUseCase {
    func execute(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

class MockSearchArticlesUseCase: SearchArticlesUseCase {
    func execute(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

class MockGetNewsSitesUseCase: GetNewsSitesUseCase {
    func execute(contentType: ContentType) -> AnyPublisher<[String], Error> {
        return Just(["SpaceNews", "NASA", "SpaceX"]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

class MockSaveRecentSearchUseCase: SaveRecentSearchUseCase {
    func execute(query: String) {
        // No-op for mock
    }
}

class MockGetRecentSearchesUseCase: GetRecentSearchesUseCase {
    func execute() -> [String] {
        return ["space", "mars", "rocket"]
    }
}

class MockClearRecentSearchesUseCase: ClearRecentSearchesUseCase {
    func execute() {
        // No-op for mock
    }
}

class MockSaveLastLoadedArticlesUseCase: SaveLastLoadedArticlesUseCase {
    func execute(articles: [Article]) {
        // No-op for mock
    }
}

class MockGetLastLoadedArticlesUseCase: GetLastLoadedArticlesUseCase {
    func execute(type: ContentType) -> [Article]? {
        return []
    }
}

class MockGetBlogsUseCase: GetBlogsUseCase {
    func execute(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

class MockSearchBlogsUseCase: SearchBlogsUseCase {
    func execute(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

class MockSaveLastLoadedBlogsUseCase: SaveLastLoadedBlogsUseCase {
    func execute(blogs: [Article]) {
        // No-op for mock
    }
}

class MockGetLastLoadedBlogsUseCase: GetLastLoadedBlogsUseCase {
    func execute() -> [Article]? {
        return []
    }
}

class MockGetReportsUseCase: GetReportsUseCase {
    func execute(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

class MockSearchReportsUseCase: SearchReportsUseCase {
    func execute(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

class MockSaveLastLoadedReportsUseCase: SaveLastLoadedReportsUseCase {
    func execute(reports: [Article]) {
        // No-op for mock
    }
}

class MockGetLastLoadedReportsUseCase: GetLastLoadedReportsUseCase {
    func execute() -> [Article]? {
        return []
    }
}

class MockLoginUseCase: LoginUseCase {
    func execute(credentials: Credentials?) -> AnyPublisher<User, AuthError> {
        let user = User(id: "mock-id", name: "Mock User", email: "mock@example.com", emailVerified: "true", picture: nil, updatedAt: nil)
        return Just(user).setFailureType(to: AuthError.self).eraseToAnyPublisher()
    }
}

class MockLogoutUseCase: LogoutUseCase {
    func execute() -> AnyPublisher<Void, AuthError> {
        return Just(()).setFailureType(to: AuthError.self).eraseToAnyPublisher()
    }
}

class MockGetCurrentUserUseCase: GetCurrentUserUseCase {
    func execute() -> User {
        return User(id: "mock-id", name: "Mock User", email: "mock@example.com", emailVerified: "true", picture: nil, updatedAt: nil)
    }
}

class MockIsLoggedInUseCase: IsLoggedInUseCase {
    func execute() -> Bool {
        return true
    }
}

class MockManageSessionUseCase: ManageSessionUseCase {
    func startSession() {
        // No-op for mock
    }
    
    func resetSession() {
        // No-op for mock
    }
    
    func stopSession() {
        // No-op for mock
    }
} 
