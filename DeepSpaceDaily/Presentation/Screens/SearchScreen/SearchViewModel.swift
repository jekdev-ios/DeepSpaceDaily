//
//  SearchViewModel.swift
//  DeepSpaceDaily
//
//  Created by admin on 28/02/25.
//

import Foundation
import Combine

class SearchViewModel: ObservableObject {
    // MARK: - Dependencies
    private let searchService: SearchService
    private let saveRecentSearchUseCase: SaveRecentSearchUseCase
    internal let getRecentSearchesUseCase: GetRecentSearchesUseCase
    private let clearRecentSearchesUseCase: ClearRecentSearchesUseCase
    private let manageSessionUseCase: ManageSessionUseCase
    private let storageModel = StorageModel.shared
    
    // MARK: - Published Properties
    @Published var searchQuery: String = "" {
        didSet {
            searchSubject.send(searchQuery)
        }
    }
    @Published var searchResults: [Article] = []
    @Published var recentSearches: [String] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published private(set) var selectedType: ContentType = .articles  // Default to articles
    @Published private(set) var sortOrder: SortOrder = .descending  // Default to newest first
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let searchSubject = PassthroughSubject<String, Never>()
    
    // MARK: - Initialization
    init(
        searchService: SearchService = SearchService(),
        saveRecentSearchUseCase: SaveRecentSearchUseCase = DependencyInjection.shared.saveRecentSearchUseCase,
        getRecentSearchesUseCase: GetRecentSearchesUseCase = DependencyInjection.shared.getRecentSearchesUseCase,
        clearRecentSearchesUseCase: ClearRecentSearchesUseCase = DependencyInjection.shared.clearRecentSearchesUseCase,
        manageSessionUseCase: ManageSessionUseCase = DependencyInjection.shared.manageSessionUseCase
    ) {
        self.searchService = searchService
        self.saveRecentSearchUseCase = saveRecentSearchUseCase
        self.getRecentSearchesUseCase = getRecentSearchesUseCase
        self.clearRecentSearchesUseCase = clearRecentSearchesUseCase
        self.manageSessionUseCase = manageSessionUseCase
        
        setupSearchDebounce()
        loadRecentSearches()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    // MARK: - Private Methods
    private func setupSearchDebounce() {
        searchSubject
            .debounce(for: .milliseconds(750), scheduler: DispatchQueue.main)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(query: String) {
        if query.isEmpty {
            if let cachedArticles = storageModel.getCachedArticles(type: selectedType) {
                searchResults = searchService.performLocalSearch(query: query, in: cachedArticles)
                return
            }
            loadAllArticles()
            return
        }
        
        storageModel.saveSearchQuery(query)
        loadRecentSearches()
        
        manageSessionUseCase.resetSession()
        
        isLoading = true
        error = nil
        
        searchService.search(
            query: query,
            type: selectedType,
            sortOrder: sortOrder
        ) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let articles):
                self.searchResults = articles
            case .failure(let error):
                self.error = error.localizedDescription
            }
        }
    }
    
    private func loadAllArticles() {
        isLoading = true
        error = nil
        
        searchService.search(
            query: searchQuery,
            type: selectedType,
            sortOrder: sortOrder
        ) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let articles):
                self.searchResults = articles
            case .failure(let error):
                self.error = error.localizedDescription
            }
        }
    }
    
    func loadRecentSearches() {
        recentSearches = storageModel.getRecentSearches()
        if !recentSearches.isEmpty {
        }
    }
    
    // MARK: - Public Methods
    func search() {
        performSearch(query: searchQuery)
    }
    
    func selectRecentSearch(_ query: String) {
        searchQuery = query
        search()
    }
    
    func clearRecentSearches() {
        storageModel.clearRecentSearches()
        recentSearches.removeAll()
    }
    
    func setContentType(_ type: ContentType) {
        selectedType = type
        search()
    }
    
    func toggleSortOrder() {
        sortOrder = sortOrder == .ascending ? .descending : .ascending
        search()
    }
} 
