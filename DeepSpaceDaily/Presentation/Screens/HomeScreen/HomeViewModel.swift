//
//  HomeViewModel.swift
//  DeepSpaceDaily
//
//  Created by admin on 28/02/25.
//

import Foundation
import Combine
import Auth0
import UserNotifications

class HomeViewModel: ObservableObject {
    // MARK: - Dependencies
    private let contentLoadingUseCase: ContentLoadingUseCase
    private let getNewsSitesUseCase: GetNewsSitesUseCase
    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let manageSessionUseCase: ManageSessionUseCase
    
    // Auth ViewModel
    let authViewModel: AuthViewModel
    
    // MARK: - Published Properties
    @Published var contentByType: [ContentType: [Article]] = [:]
//    {
//        willSet {
//            print("[HomeViewModel.contentByType] will be updated:")
//            
//            for (type, articles) in newValue {
//                print("[HomeViewModel.contentByType]  - \(type.rawValue): \(articles.count) articles")
//                
//                // Only print first 3 articles to avoid console spam
//                for (index, article) in articles.prefix(3).enumerated() {
//                    print("[HomeViewModel.contentByType] \(index): \(article.title): \(article.publishedAt)")
//                }
//                if articles.count > 3 {
//                    print("[HomeViewModel.contentByType] ... and \(articles.count - 3) more articles")
//                }
//            }
//            print("[HomeViewModel.contentByType] ----------------------")
//        }
//    }
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var newsSites: [String] = []
    @Published var selectedNewsSite: String? = nil
    @Published var sortOrder: SortOrder = .descending
    @Published var greeting: String = ""
    @Published var currentContentType: ContentType = .articles
    @Published var isSorting: Bool = false // Track if sorting is in progress
    @Published var apiCallCount: Int = 0 // Track the number of API calls
    @Published var showAPIStats: Bool = false // Toggle to show/hide API stats
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var sortDebounceTimer: Timer?
    private var siteSelectionDebounceTimer: Timer?
    
    // Fallback news sites in case the API call fails
    private let fallbackNewsSites = [
        "NASA", "SpaceX", "ESA", "Roscosmos", "Blue Origin", 
        "Spaceflight Now", "Space.com", "Ars Technica", "The Verge"
    ]
    
    // MARK: - Initialization
    init(
        contentLoadingUseCase: ContentLoadingUseCase = DependencyInjection.shared.contentLoadingUseCase,
        getNewsSitesUseCase: GetNewsSitesUseCase = DependencyInjection.shared.getNewsSitesUseCase,
        getCurrentUserUseCase: GetCurrentUserUseCase = DependencyInjection.shared.getCurrentUserUseCase,
        manageSessionUseCase: ManageSessionUseCase = DependencyInjection.shared.manageSessionUseCase,
        authViewModel: AuthViewModel = AuthViewModel()
    ) {
        print("[HomeViewModel] Initializing")
        self.contentLoadingUseCase = contentLoadingUseCase
        self.getNewsSitesUseCase = getNewsSitesUseCase
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.manageSessionUseCase = manageSessionUseCase
        self.authViewModel = authViewModel
        
        setupGreeting()
        
        authViewModel.$currentUser
            .sink { [weak self] user in
                print("[HomeViewModel] Auth user changed: id=\(user.id), name=\(user.name)")
                self?.setupGreeting()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func loadArticles(_ selectedType: [ContentType] = ContentType.allCases) {
        isLoading = true
        error = nil

        let group = DispatchGroup()
        
        for type in selectedType {
            group.enter()
            
            contentLoadingUseCase.loadContent(for: type, newsSite: selectedNewsSite, sortOrder: sortOrder)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        switch completion {
                        case .failure(let error):
                            print("[HomeViewModel] Error loading \(type.rawValue): \(error.localizedDescription)")
                            self?.error = error.localizedDescription
                        case .finished:
                            break
                        }
                        group.leave()
                    },
                    receiveValue: { [weak self] articles in
                        self?.loadNewsSites(for: self?.currentContentType ?? .articles)
                        
                        self?.setContent(self?.applyFilter(articles) ?? articles, for: type, source: "loadArticles()")
                    }
                )
                .store(in: &cancellables)
        }
                
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
            self?.isSorting = false // Reset sorting flag when loading completes
            // Update API call count after all requests are completed
            self?.updateAPICallCount()
        }
    }
    
    func toggleSortOrder() {
        // If already sorting or loading, ignore the request
        guard !isSorting && !isLoading else {
            print("[HomeViewModel1] Ignoring sort order toggle - operation in progress")
            return
        }
        
        // Cancel any existing timer
        sortDebounceTimer?.invalidate()
        
        // Set sorting flag to prevent multiple clicks
        isSorting = true
        
        // Create a new timer with a short delay
        sortDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            let oldSortOrder = self.sortOrder
            let newSortOrder = oldSortOrder == .ascending ? SortOrder.descending : SortOrder.ascending
            
            print("[HomeViewModel1] Toggling sort order from \(oldSortOrder) to \(newSortOrder)")
            self.sortOrder = newSortOrder
            
            print("[HomeViewModel1] Loading articles with new sort order: \(self.sortOrder)")
            self.loadArticles([currentContentType]) // This will reset isSorting when complete
            
            // Log the completion of the sort order change
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("[HomeViewModel1] \(self.currentContentType.rawValue) Sort order changed to: \(self.sortOrder)")
            }
        }
    }
    
    func selectNewsSite(_ newsSite: String?) {
        // If already sorting or loading, ignore the request
        guard !isSorting && !isLoading else {
            print("[HomeViewModel] Ignoring news site selection - operation in progress")
            return
        }
        
        // Cancel any existing timer
        siteSelectionDebounceTimer?.invalidate()
        
        // Set sorting flag to prevent multiple clicks
        isSorting = true
        
        // Create a new timer with a short delay
        siteSelectionDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            print("[HomeViewModel] Selecting news site: \(newsSite ?? "All Sites")")
            self.selectedNewsSite = newsSite
            self.loadArticles() // This will reset isSorting when complete
        }
    }
    
    func resetSession() {
        manageSessionUseCase.resetSession()
    }
    
    // New public method to reload news sites
    func reloadNewsSites() {
        print("[HomeViewModel] Manually reloading news sites for content type: \(currentContentType.rawValue)")
        loadNewsSites(for: currentContentType)
    }
    
    // New method to set content type and reload news sites
    func setContentType(_ type: ContentType) {
        print("[HomeViewModel] Setting content type to: \(type.rawValue)")
        currentContentType = type
        loadNewsSites(for: type)
    }
    
    // MARK: - API Call Statistics
    
    /// Updates the API call count from the APIService
    func updateAPICallCount() {
        apiCallCount = APIService.getAPICallCount()
        print("📊 Total API calls made: \(apiCallCount)")
    }
    
    /// Toggles the display of API statistics
    func toggleAPIStats() {
        showAPIStats.toggle()
        if showAPIStats {
            updateAPICallCount()
        }
    }
    
    /// Resets the API call counter
    func resetAPICallCount() {
        APIService.resetAPICallCount()
        updateAPICallCount()
    }
    
    // MARK: - Private Methods
    private func setContent(_ content: [Article], for type: ContentType, source: String) {
        print("[HomeViewModel] setContent() called from \(source) for type \(type.rawValue) with \(content.count) articles")
        contentByType[type] = content
    }
    
    private func setupGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            greeting = "Good morning"
        case 12..<17:
            greeting = "Good afternoon"
        default:
            greeting = "Good evening"
        }
    }
    
    private func loadNewsSites(for contentType: ContentType) {
        print("[HomeViewModel] Starting to load news sites for content type: \(contentType.rawValue)")
        getNewsSitesUseCase.execute(contentType: contentType)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    switch result {
                    case .failure(let error):
                        print("[HomeViewModel] Error loading news sites: \(error.localizedDescription)")
                        print("[HomeViewModel] Detailed error: \(error)")
                        self?.error = error.localizedDescription
                        
                        // Use fallback data if API call fails
                        print("[HomeViewModel] Using fallback news sites")
                        self?.newsSites = self?.fallbackNewsSites ?? []
                        print("[HomeViewModel] Set fallback news sites: \(self?.newsSites ?? [])")
                        
                    case .finished:
                        print("[HomeViewModel] News sites loading completed successfully")
                        break
                    }
                },
                receiveValue: { [weak self] sites in
                    print("[HomeViewModel] Received news sites: \(sites)")
                    print("[HomeViewModel] Number of sites: \(sites.count)")
                    
                    if sites.isEmpty {
                        print("[HomeViewModel] Received empty sites array, using fallback data")
                        self?.newsSites = self?.fallbackNewsSites ?? []
                    } else {
                        self?.newsSites = sites
                    }
                    
                    print("[HomeViewModel] Updated newsSites property: \(self?.newsSites ?? [])")
                }
            )
            .store(in: &cancellables)
    }
    
    private func applyFilter(_ articles: [Article]) -> [Article] {
        switch sortOrder {
            case .ascending:
                return articles.sorted { $0.publishedAt < $1.publishedAt }
            case .descending:
                return articles.sorted { $0.publishedAt > $1.publishedAt }
            default:
                return articles
        }
    }
}
