//
//  BlogUseCases.swift
//  DeepSpaceDaily
//
//  Created by admin on 28/02/25.
//

import Foundation
import Combine

protocol GetBlogsUseCase {
    func execute(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error>
}

protocol SearchBlogsUseCase {
    func execute(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error>
}

protocol SaveLastLoadedBlogsUseCase {
    func execute(blogs: [Article])
}

protocol GetLastLoadedBlogsUseCase {
    func execute() -> [Article]?
}

// Implementations

class GetBlogsUseCaseImpl: GetBlogsUseCase {
    private let repository: any BlogRepository
    
    init(repository: any BlogRepository) {
        self.repository = repository
    }
    
    func execute(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return repository.getItems(page: page, limit: limit, sortOrder: sortOrder)
    }
}

class SearchBlogsUseCaseImpl: SearchBlogsUseCase {
    private let repository: any BlogRepository
    
    init(repository: any BlogRepository) {
        self.repository = repository
    }
    
    func execute(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return repository.searchItems(query: query, page: page, limit: limit, sortOrder: sortOrder)
    }
}

class SaveLastLoadedBlogsUseCaseImpl: SaveLastLoadedBlogsUseCase {
    private let repository: any BlogRepository
    
    init(repository: any BlogRepository) {
        self.repository = repository
    }
    
    func execute(blogs: [Article]) {
        repository.saveLastLoadedItems(items: blogs)
    }
}

class GetLastLoadedBlogsUseCaseImpl: GetLastLoadedBlogsUseCase {
    private let repository: any BlogRepository
    
    init(repository: any BlogRepository) {
        self.repository = repository
    }
    
    func execute() -> [Article]? {
        return repository.getLastLoadedItems()
    }
} 
