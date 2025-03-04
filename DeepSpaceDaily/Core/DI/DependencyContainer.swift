//
//  DependencyContainer.swift
//  DeepSpaceDaily
//
//  Created by admin on 03/03/25.
//

import Foundation

/// Protocol defining the dependencies that can be injected
protocol DependencyContainer {
    // MARK: - Services
    var apiService: APIService { get }
    var storageModel: StorageModel { get }
    
    // MARK: - Repositories
    var articleRepository: any ArticleRepository { get }
    var blogRepository: any BlogRepository { get }
    var reportRepository: any ReportRepository { get }
    var newsSiteRepository: any NewsSiteRepository { get }
    var searchRepository: any SearchRepository { get }
    var authRepository: any AuthRepository { get }
    
    // MARK: - Use Cases
    var contentLoadingUseCase: ContentLoadingUseCase { get }
    var getArticlesUseCase: GetArticlesUseCase { get }
    var searchArticlesUseCase: SearchArticlesUseCase { get }
    var getNewsSitesUseCase: GetNewsSitesUseCase { get }
    var saveRecentSearchUseCase: SaveRecentSearchUseCase { get }
    var getRecentSearchesUseCase: GetRecentSearchesUseCase { get }
    var clearRecentSearchesUseCase: ClearRecentSearchesUseCase { get }
    var saveLastLoadedArticlesUseCase: SaveLastLoadedArticlesUseCase { get }
    var getLastLoadedArticlesUseCase: GetLastLoadedArticlesUseCase { get }
    var getBlogsUseCase: GetBlogsUseCase { get }
    var searchBlogsUseCase: SearchBlogsUseCase { get }
    var saveLastLoadedBlogsUseCase: SaveLastLoadedBlogsUseCase { get }
    var getLastLoadedBlogsUseCase: GetLastLoadedBlogsUseCase { get }
    var getReportsUseCase: GetReportsUseCase { get }
    var searchReportsUseCase: SearchReportsUseCase { get }
    var saveLastLoadedReportsUseCase: SaveLastLoadedReportsUseCase { get }
    var getLastLoadedReportsUseCase: GetLastLoadedReportsUseCase { get }
    var loginUseCase: LoginUseCase { get }
    var logoutUseCase: LogoutUseCase { get }
    var getCurrentUserUseCase: GetCurrentUserUseCase { get }
    var isLoggedInUseCase: IsLoggedInUseCase { get }
    var manageSessionUseCase: ManageSessionUseCase { get }
} 