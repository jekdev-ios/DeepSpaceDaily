//
//  ArticleUseCases.swift
//  DeepSpaceDaily
//
//  Created by admin on 28/02/25.
//

import Foundation
import Combine

protocol GetArticlesUseCase {
    func execute(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error>
}

protocol SearchArticlesUseCase {
    func execute(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error>
}

protocol GetNewsSitesUseCase {
    func execute(contentType: ContentType) -> AnyPublisher<[String], Error>
}

protocol SaveRecentSearchUseCase {
    func execute(query: String)
}

protocol GetRecentSearchesUseCase {
    func execute() -> [String]
}

protocol ClearRecentSearchesUseCase {
    func execute()
}

protocol SaveLastLoadedArticlesUseCase {
    func execute(articles: [Article])
}

protocol GetLastLoadedArticlesUseCase {
    func execute(type: ContentType) -> [Article]?
}

// Implementations

class GetArticlesUseCaseImpl: GetArticlesUseCase {
    private let repository: any ArticleRepository
    
    init(repository: any ArticleRepository) {
        self.repository = repository
    }
    
    func execute(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return repository.getItems(page: page, limit: limit, sortOrder: sortOrder)
    }
}

class SearchArticlesUseCaseImpl: SearchArticlesUseCase {
    private let repository: any ArticleRepository
    
    init(repository: any ArticleRepository) {
        self.repository = repository
    }
    
    func execute(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return repository.searchItems(query: query, page: page, limit: limit, sortOrder: sortOrder)
    }
}

class GetNewsSitesUseCaseImpl: GetNewsSitesUseCase {
    private let repository: any NewsSiteRepository
    
    init(repository: any NewsSiteRepository) {
        self.repository = repository
    }
    
    func execute(contentType: ContentType) -> AnyPublisher<[String], Error> {
        return repository.getNewsSites(contentType: contentType)
    }
}

class SaveRecentSearchUseCaseImpl: SaveRecentSearchUseCase {
    private let repository: any SearchRepository
    
    init(repository: any SearchRepository) {
        self.repository = repository
    }
    
    func execute(query: String) {
        repository.saveRecentSearch(query: query)
    }
}

class GetRecentSearchesUseCaseImpl: GetRecentSearchesUseCase {
    private let repository: any SearchRepository
    
    init(repository: any SearchRepository) {
        self.repository = repository
    }
    
    func execute() -> [String] {
        return repository.getRecentSearches()
    }
}

class ClearRecentSearchesUseCaseImpl: ClearRecentSearchesUseCase {
    private let repository: any SearchRepository
    
    init(repository: any SearchRepository) {
        self.repository = repository
    }
    
    func execute() {
        repository.clearRecentSearches()
    }
}

class SaveLastLoadedArticlesUseCaseImpl: SaveLastLoadedArticlesUseCase {
    private let repository: any ArticleRepository
    
    init(repository: any ArticleRepository) {
        self.repository = repository
    }
    
    func execute(articles: [Article]) {
        repository.saveLastLoadedItems(items: articles)
    }
}

class GetLastLoadedArticlesUseCaseImpl: GetLastLoadedArticlesUseCase {
    private let repository: any ArticleRepository
    
    init(repository: any ArticleRepository) {
        self.repository = repository
    }
    
    func execute(type: ContentType) -> [Article]? {
        return repository.getLastLoadedItems()
    }
}
