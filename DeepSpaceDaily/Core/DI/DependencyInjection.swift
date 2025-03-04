//
//  DependencyInjection.swift
//  DeepSpaceDaily
//
//  Created by admin on 29/02/25.
//

import Foundation
import Combine

// Simple DI container
class DependencyInjection: DependencyContainer {
    static let shared = DependencyInjection()
    
    // Track initialization to prevent circular dependencies
    private var isInitializingSpaceNewsRepository = false
    
    // SSL validation mode
    private var sslValidationMode: SSLValidationMode = .standard
    
    private init() {
    }
    
    deinit {
    }
    
    /// Configure the SSL validation mode for the app
    /// - Parameter mode: The SSL validation mode to use
    func configureSSL(mode: SSLValidationMode) {
        self.sslValidationMode = .standard
        
        // Update existing API service if it has been initialized
        if let apiService = _apiService {
            apiService.updateSSLValidationMode(mode)
        }
    }
    
    // MARK: - Data Layer
    
    // Private backing property for apiService
    private var _apiService: APIService?
    
    private(set) lazy var apiService: APIService = {
        let service = APIService(sslValidationMode: sslValidationMode)
        _apiService = service
        return service
    }()
    
    private(set) lazy var storageModel: StorageModel = {
        return StorageModel.shared
    }()
    
    // MARK: - Repositories
    
    lazy var articleRepository: any ArticleRepository = {
        return ArticleRepositoryImpl(apiService: apiService, storageModel: storageModel)
    }()
    
    lazy var blogRepository: any BlogRepository = {
        return BlogRepositoryImpl(apiService: apiService, storageModel: storageModel)
    }()
    
    lazy var reportRepository: any ReportRepository = {
        return ReportRepositoryImpl(apiService: apiService, storageModel: storageModel)
    }()
    
    lazy var newsSiteRepository: any NewsSiteRepository = {
        return NewsSiteRepositoryImpl(
            apiService: apiService,
            articleRepository: articleRepository,
            blogRepository: blogRepository,
            reportRepository: reportRepository
        )
    }()
    
    lazy var searchRepository: any SearchRepository = {
        return SearchRepositoryImpl(storageModel: storageModel)
    }()
    
    lazy var authRepository: any AuthRepository = {
        return AuthRepositoryImpl()
    }()
    
    // MARK: - Use Cases
    
    // Content Loading Use Case
    lazy var contentLoadingUseCase: ContentLoadingUseCase = {
        return ContentLoadingUseCaseImpl(
            articleRepository: articleRepository,
            blogRepository: blogRepository,
            reportRepository: reportRepository
        )
    }()
    
    // Article Use Cases
    lazy var getArticlesUseCase: GetArticlesUseCase = {
        return GetArticlesUseCaseImpl(repository: articleRepository)
    }()
    
    lazy var searchArticlesUseCase: SearchArticlesUseCase = {
        return SearchArticlesUseCaseImpl(repository: articleRepository)
    }()
    
    lazy var getNewsSitesUseCase: GetNewsSitesUseCase = {
        return GetNewsSitesUseCaseImpl(repository: newsSiteRepository)
    }()
    
    lazy var saveRecentSearchUseCase: SaveRecentSearchUseCase = {
        return SaveRecentSearchUseCaseImpl(repository: searchRepository)
    }()
    
    lazy var getRecentSearchesUseCase: GetRecentSearchesUseCase = {
        return GetRecentSearchesUseCaseImpl(repository: searchRepository)
    }()
    
    lazy var clearRecentSearchesUseCase: ClearRecentSearchesUseCase = {
        return ClearRecentSearchesUseCaseImpl(repository: searchRepository)
    }()
    
    lazy var saveLastLoadedArticlesUseCase: SaveLastLoadedArticlesUseCase = {
        return SaveLastLoadedArticlesUseCaseImpl(repository: articleRepository)
    }()
    
    lazy var getLastLoadedArticlesUseCase: GetLastLoadedArticlesUseCase = {
        return GetLastLoadedArticlesUseCaseImpl(repository: articleRepository)
    }()
    
    // Blog Use Cases
    lazy var getBlogsUseCase: GetBlogsUseCase = {
        return GetBlogsUseCaseImpl(repository: blogRepository)
    }()
    
    lazy var searchBlogsUseCase: SearchBlogsUseCase = {
        return SearchBlogsUseCaseImpl(repository: blogRepository)
    }()
    
    lazy var saveLastLoadedBlogsUseCase: SaveLastLoadedBlogsUseCase = {
        return SaveLastLoadedBlogsUseCaseImpl(repository: blogRepository)
    }()
    
    lazy var getLastLoadedBlogsUseCase: GetLastLoadedBlogsUseCase = {
        return GetLastLoadedBlogsUseCaseImpl(repository: blogRepository)
    }()
    
    // Report Use Cases
    lazy var getReportsUseCase: GetReportsUseCase = {
        return GetReportsUseCaseImpl(repository: reportRepository)
    }()
    
    lazy var searchReportsUseCase: SearchReportsUseCase = {
        return SearchReportsUseCaseImpl(repository: reportRepository)
    }()
    
    lazy var saveLastLoadedReportsUseCase: SaveLastLoadedReportsUseCase = {
        return SaveLastLoadedReportsUseCaseImpl(repository: reportRepository)
    }()
    
    lazy var getLastLoadedReportsUseCase: GetLastLoadedReportsUseCase = {
        return GetLastLoadedReportsUseCaseImpl(repository: reportRepository)
    }()
    
    // Auth Use Cases
    lazy var loginUseCase: LoginUseCase = {
        return LoginUseCaseImpl(repository: authRepository)
    }()
    
    lazy var logoutUseCase: LogoutUseCase = {
        return LogoutUseCaseImpl(repository: authRepository)
    }()
    
    lazy var getCurrentUserUseCase: GetCurrentUserUseCase = {
        return GetCurrentUserUseCaseImpl(repository: authRepository)
    }()
    
    lazy var isLoggedInUseCase: IsLoggedInUseCase = {
        return IsLoggedInUseCaseImpl(repository: authRepository)
    }()
    
    lazy var manageSessionUseCase: ManageSessionUseCase = {
        return ManageSessionUseCaseImpl(repository: authRepository)
    }()
} 
