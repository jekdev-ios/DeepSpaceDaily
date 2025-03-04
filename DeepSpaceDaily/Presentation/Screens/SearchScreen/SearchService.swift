//
//  SearchService.swift
//  DeepSpaceDaily
//
//  Created by admin on 29/02/25.
//

import Foundation
import Combine

class SearchService {
    // MARK: - Dependencies
    private let searchArticlesUseCase: SearchArticlesUseCase
    private let searchBlogsUseCase: SearchBlogsUseCase
    private let searchReportsUseCase: SearchReportsUseCase
    private let storageModel = StorageModel.shared
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        searchArticlesUseCase: SearchArticlesUseCase = DependencyInjection.shared.searchArticlesUseCase,
        searchBlogsUseCase: SearchBlogsUseCase = DependencyInjection.shared.searchBlogsUseCase,
        searchReportsUseCase: SearchReportsUseCase = DependencyInjection.shared.searchReportsUseCase
    ) {
        self.searchArticlesUseCase = searchArticlesUseCase
        self.searchBlogsUseCase = searchBlogsUseCase
        self.searchReportsUseCase = searchReportsUseCase
    }
    
    // MARK: - Public Methods
    func search(
        query: String,
        type: ContentType,
        sortOrder: SortOrder,
        completion: @escaping (Result<[Article], Error>) -> Void
    ) {
        if query.isEmpty {
            if let cachedArticles = storageModel.getCachedArticles(type: type) {
                completion(.success(sortArticles(cachedArticles, sortOrder: sortOrder)))
                return
            }
            loadAllArticles(type: type, sortOrder: sortOrder, completion: completion)
            return
        }
        
        // Try to search in cached articles first
        if let results = storageModel.searchArticles(query: query, type: type) {
            completion(.success(sortArticles(results, sortOrder: sortOrder)))
            return
        }
        
        // If no cached results, load from network
        loadAllArticles(type: type, sortOrder: sortOrder, completion: completion)
    }
    
    func performLocalSearch(query: String, in articles: [Article]) -> [Article] {
        let searchTerms = query.lowercased().split(separator: " ")
        return articles.filter { article in
            let title = article.title.lowercased()
            let summary = article.summary.lowercased()
            
            return searchTerms.allSatisfy { term in
                title.contains(term) || summary.contains(term)
            }
        }
    }
    
    // MARK: - Private Methods
    private func loadAllArticles(
        type: ContentType,
        sortOrder: SortOrder,
        completion: @escaping (Result<[Article], Error>) -> Void
    ) {
        // First try to search locally in cached articles
        if let cachedArticles = storageModel.getCachedArticles(type: type) {
            let localResults = performLocalSearch(query: "", in: cachedArticles)
            if !localResults.isEmpty {
                completion(.success(sortArticles(localResults, sortOrder: sortOrder)))
                return
            }
        }
        
        let publisher: AnyPublisher<[Article], Error>
        switch type {
        case .articles:
            publisher = searchArticlesUseCase.execute(query: "", page: 1, limit: 100, sortOrder: sortOrder)
        case .blogs:
            publisher = searchBlogsUseCase.execute(query: "", page: 1, limit: 100, sortOrder: sortOrder)
        case .reports:
            publisher = searchReportsUseCase.execute(query: "", page: 1, limit: 100, sortOrder: sortOrder)
        }
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { result in
                    if case .failure(let error) = result {
                        completion(.failure(error))
                    }
                },
                receiveValue: { articles in
                    // Cache the articles
                    self.storageModel.saveArticles(articles, type: type)
                    
                    completion(.success(self.sortArticles(articles, sortOrder: sortOrder)))
                }
            )
            .store(in: &cancellables)
    }
    
    private func sortArticles(_ articles: [Article], sortOrder: SortOrder) -> [Article] {
        return articles.sorted { first, second in
            switch sortOrder {
            case .ascending:
                return first.updatedAt < second.updatedAt
            case .descending:
                return first.updatedAt > second.updatedAt
            case .publishedAt:
                return first.publishedAt > second.publishedAt
            case .updatedAt:
                return first.updatedAt > second.updatedAt
            case .title:
                return first.title < second.title
            }
        }
    }
} 