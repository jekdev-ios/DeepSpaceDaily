//
//  ContentLoadingService.swift
//  DeepSpaceDaily
//
//  Created by admin on 29/02/25.
//
//

import Foundation
import Combine

class ContentLoadingService {
    // MARK: - Dependencies
    private let getArticlesUseCase: GetArticlesUseCase
    private let getBlogsUseCase: GetBlogsUseCase
    private let getReportsUseCase: GetReportsUseCase
    private let getLastLoadedArticlesUseCase: GetLastLoadedArticlesUseCase
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let articlesPerPage = 10
    
    // MARK: - Initialization
    init(
        getArticlesUseCase: GetArticlesUseCase = DependencyInjection.shared.getArticlesUseCase,
        getBlogsUseCase: GetBlogsUseCase = DependencyInjection.shared.getBlogsUseCase,
        getReportsUseCase: GetReportsUseCase = DependencyInjection.shared.getReportsUseCase,
        getLastLoadedArticlesUseCase: GetLastLoadedArticlesUseCase = DependencyInjection.shared.getLastLoadedArticlesUseCase
    ) {
        self.getArticlesUseCase = getArticlesUseCase
        self.getBlogsUseCase = getBlogsUseCase
        self.getReportsUseCase = getReportsUseCase
        self.getLastLoadedArticlesUseCase = getLastLoadedArticlesUseCase
    }
    
    // MARK: - Public Methods
    func loadContent(
        type: ContentType,
        newsSite: String?,
        sortOrder: SortOrder,
        completion: @escaping (Result<[Article], Error>) -> Void
    ) {
        let useCase = getUseCase(for: type)
        fetchContent(useCase: useCase, newsSite: newsSite, sortOrder: sortOrder, completion: completion)
    }
    
    func loadLastSavedArticles(type: ContentType) -> [Article] {
        return getLastLoadedArticlesUseCase.execute(type: type) ?? []
    }
    
    // MARK: - Private Methods
    private func getUseCase(for type: ContentType) -> (Int, Int, SortOrder) -> AnyPublisher<[Article], Error> {
        switch type {
        case .articles: return getArticlesUseCase.execute
        case .blogs: return getBlogsUseCase.execute
        case .reports: return getReportsUseCase.execute
        }
    }
    
    private func fetchContent(
        useCase: (Int, Int, SortOrder) -> AnyPublisher<[Article], Error>,
        newsSite: String?,
        sortOrder: SortOrder,
        completion: @escaping (Result<[Article], Error>) -> Void
    ) {
        let limit = newsSite == nil ? articlesPerPage : 50
        
        useCase(1, limit, sortOrder)
            .receive(on: DispatchQueue.main)
            .map { articles in
                newsSite == nil ? articles : articles.filter { $0.newsSite == newsSite }
            }
            .sink(receiveCompletion: { result in
                if case let .failure(error) = result {
                    completion(.failure(error))
                }
            }, receiveValue: { content in
                completion(.success(content))
            })
            .store(in: &cancellables)
    }
}
