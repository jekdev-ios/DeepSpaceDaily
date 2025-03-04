//
//  NewsSiteRepositoryImpl.swift
//  DeepSpaceDaily
//
//  Created by admin on 03/03/25.
//

import Foundation
import Combine

// MARK: - News Site Repository Implementation
class NewsSiteRepositoryImpl: NewsSiteRepository {
    private let apiService: APIService
    private let articleRepository: any ArticleRepository
    private let blogRepository: any BlogRepository
    private let reportRepository: any ReportRepository
    
    init(
        apiService: APIService,
        articleRepository: any ArticleRepository,
        blogRepository: any BlogRepository,
        reportRepository: any ReportRepository
    ) {
        self.apiService = apiService
        self.articleRepository = articleRepository
        self.blogRepository = blogRepository
        self.reportRepository = reportRepository
    }
    
    func getNewsSites(contentType: ContentType) -> AnyPublisher<[String], Error> {
        // First, try to get news sites from cached content
        var cachedSites: [String] = []
        
        switch contentType {
        case .articles:
            if let articles = articleRepository.getLastLoadedItems() {
                cachedSites = extractNewsSites(from: articles)
            }
        case .blogs:
            if let blogs = blogRepository.getLastLoadedItems() {
                cachedSites = extractNewsSites(from: blogs)
            }
        case .reports:
            if let reports = reportRepository.getLastLoadedItems() {
                cachedSites = extractNewsSites(from: reports)
            }
        }
        
        // If we have cached sites, return them
        if !cachedSites.isEmpty {
            return Just(cachedSites)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Otherwise, fetch new content and extract sites
        switch contentType {
        case .articles:
            return articleRepository.getItems(page: 1, limit: 50, sortOrder: .descending)
                .map { articles -> [String] in
                    let sites = self.extractNewsSites(from: articles)
                    return sites
                }
                .eraseToAnyPublisher()
                
        case .blogs:
            return blogRepository.getItems(page: 1, limit: 50, sortOrder: .descending)
                .map { blogs -> [String] in
                    let sites = self.extractNewsSites(from: blogs)
                    return sites
                }
                .eraseToAnyPublisher()
                
        case .reports:
            return reportRepository.getItems(page: 1, limit: 50, sortOrder: .descending)
                .map { reports -> [String] in
                    let sites = self.extractNewsSites(from: reports)
                    return sites
                }
                .eraseToAnyPublisher()
        }
    }
    
    private func extractNewsSites(from articles: [Article]) -> [String] {
        // Extract unique news sites from articles
        let sites = Set(articles.map { $0.newsSite })
        return Array(sites).sorted()
    }
} 
