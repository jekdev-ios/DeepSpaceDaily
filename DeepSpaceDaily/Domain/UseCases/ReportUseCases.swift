//
//  ReportUseCases.swift
//  DeepSpaceDaily
//
//  Created by admin on 28/02/25.
//

import Foundation
import Combine

protocol GetReportsUseCase {
    func execute(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error>
}

protocol SearchReportsUseCase {
    func execute(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error>
}

protocol SaveLastLoadedReportsUseCase {
    func execute(reports: [Article])
}

protocol GetLastLoadedReportsUseCase {
    func execute() -> [Article]?
}

// Implementations

class GetReportsUseCaseImpl: GetReportsUseCase {
    private let repository: any ReportRepository
    
    init(repository: any ReportRepository) {
        self.repository = repository
    }
    
    func execute(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return repository.getItems(page: page, limit: limit, sortOrder: sortOrder)
    }
}

class SearchReportsUseCaseImpl: SearchReportsUseCase {
    private let repository: any ReportRepository
    
    init(repository: any ReportRepository) {
        self.repository = repository
    }
    
    func execute(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return repository.searchItems(query: query, page: page, limit: limit, sortOrder: sortOrder)
    }
}

class SaveLastLoadedReportsUseCaseImpl: SaveLastLoadedReportsUseCase {
    private let repository: any ReportRepository
    
    init(repository: any ReportRepository) {
        self.repository = repository
    }
    
    func execute(reports: [Article]) {
        repository.saveLastLoadedItems(items: reports)
    }
}

class GetLastLoadedReportsUseCaseImpl: GetLastLoadedReportsUseCase {
    private let repository: any ReportRepository
    
    init(repository: any ReportRepository) {
        self.repository = repository
    }
    
    func execute() -> [Article]? {
        return repository.getLastLoadedItems()
    }
} 
