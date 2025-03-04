//
//  SearchRepositoryImpl.swift
//  DeepSpaceDaily
//
//  Created by admin on 03/03/25.
//

import Foundation
import Combine

// MARK: - Search Repository Implementation
class SearchRepositoryImpl: SearchRepository {
    private let storageModel: StorageModel
    
    init(storageModel: StorageModel = .shared) {
        self.storageModel = storageModel
    }
    
    func saveRecentSearch(query: String) {
        do {
            try storageModel.searchHistory.saveSearchQuery(query)
        } catch {
            print("[SearchRepositoryImpl] Failed to save search query: \(error.localizedDescription)")
        }
    }
    
    func getRecentSearches() -> [String] {
        do {
            return try storageModel.searchHistory.getRecentSearches()
        } catch {
            print("[SearchRepositoryImpl] Failed to get recent searches: \(error.localizedDescription)")
            return []
        }
    }
    
    func clearRecentSearches() {
        do {
            try storageModel.searchHistory.clearSearchHistory()
        } catch {
            print("[SearchRepositoryImpl] Failed to clear search history: \(error.localizedDescription)")
        }
    }
} 