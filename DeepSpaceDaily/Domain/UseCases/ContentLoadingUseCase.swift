//
//  ContentLoadingUseCase.swift
//  DeepSpaceDaily
//
//  Created by admin on 03/03/25.
//

import Foundation
import Combine

protocol ContentLoadingUseCase {
    func loadContent(for contentType: ContentType, newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error>
    func loadMoreContent(for contentType: ContentType, newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error>
    func refreshContent(for contentType: ContentType, newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error>
}

class ContentLoadingUseCaseImpl: ContentLoadingUseCase {
    private let articleRepository: any ArticleRepository
    private let blogRepository: any BlogRepository
    private let reportRepository: any ReportRepository
    
    init(
        articleRepository: any ArticleRepository,
        blogRepository: any BlogRepository,
        reportRepository: any ReportRepository
    ) {
        self.articleRepository = articleRepository
        self.blogRepository = blogRepository
        self.reportRepository = reportRepository
    }
    
    func loadContent(for contentType: ContentType, newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        switch contentType {
        case .articles:
            return articleRepository.getArticles(newsSite: newsSite, sortOrder: sortOrder)
        case .blogs:
            return blogRepository.getBlogs(newsSite: newsSite, sortOrder: sortOrder)
        case .reports:
            return reportRepository.getReports(newsSite: newsSite, sortOrder: sortOrder)
        }
    }
    
    func loadMoreContent(for contentType: ContentType, newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        switch contentType {
        case .articles:
            return articleRepository.loadMoreArticles(newsSite: newsSite, sortOrder: sortOrder)
        case .blogs:
            return blogRepository.loadMoreBlogs(newsSite: newsSite, sortOrder: sortOrder)
        case .reports:
            return reportRepository.loadMoreReports(newsSite: newsSite, sortOrder: sortOrder)
        }
    }
    
    func refreshContent(for contentType: ContentType, newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        switch contentType {
        case .articles:
            return articleRepository.refreshArticles(newsSite: newsSite, sortOrder: sortOrder)
        case .blogs:
            return blogRepository.refreshBlogs(newsSite: newsSite, sortOrder: sortOrder)
        case .reports:
            return reportRepository.refreshReports(newsSite: newsSite, sortOrder: sortOrder)
        }
    }
} 