//
//  ArticleRepository.swift
//  DeepSpaceDaily
//
//  Created by admin on 28/02/25.
//

//import Foundation
//import Combine
//
//enum SortOrder {
//    case ascending
//    case descending
//}
//
//// Base protocol for all content repositories
//protocol ContentRepository {
//    associatedtype T
//    func getItems(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[T], Error>
//    func searchItems(query: String, page: Int, limit: Int) -> AnyPublisher<[T], Error>
//    func getItemsByNewsSite(newsSite: String, page: Int, limit: Int) -> AnyPublisher<[T], Error>
//    func saveLastLoadedItems(items: [T])
//    func getLastLoadedItems() -> [T]?
//}
//
//// Specific repository for Articles
//protocol ArticleRepository: ContentRepository where T == Article {
//    func getArticles(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error>
//    func searchArticles(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error>
//}
//
//// Specific repository for Blogs
//protocol BlogRepository: ContentRepository where T == Article {
//    func getBlogs(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error>
//    func searchBlogs(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error>
//    func getBlogsByNewsSite(newsSite: String, page: Int, limit: Int) -> AnyPublisher<[Article], Error>
//    func saveLastLoadedBlogs(blogs: [Article])
//    func getLastLoadedBlogs() -> [Article]?
//}
//
//// Specific repository for Reports
//protocol ReportRepository: ContentRepository where T == Article {
//    func getReports(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error>
//    func searchReports(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Article], Error>
//    func getReportsByNewsSite(newsSite: String, page: Int, limit: Int) -> AnyPublisher<[Article], Error>
//    func saveLastLoadedReports(reports: [Article])
//    func getLastLoadedReports() -> [Article]?
//}
//
//// Common repository for news sites
//protocol NewsSiteRepository {
//    func getNewsSites(contentType: ContentType) -> AnyPublisher<[String], Error>
//}
//
//// Repository for recent searches
//protocol SearchRepository {
//    func saveRecentSearch(query: String)
//    func getRecentSearches() -> [String]
//    func clearRecentSearches()
//}
//
//// Combined repository that provides access to all content types
//protocol SpaceNewsRepository: ArticleRepository, BlogRepository, ReportRepository, NewsSiteRepository, SearchRepository {
//    // This protocol combines all the specific repositories
//} 

import Foundation
import Combine

/// Sort order for article queries
enum SortOrder: String {
    case ascending = "asc"
    case descending = "desc"
    case publishedAt = "published_at"
    case updatedAt = "updated_at"
    case title = "title"
}

// Base protocol for all content repositories
protocol ContentRepository {
    associatedtype Item
    func getItems(page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Item], Error>
    func searchItems(query: String, page: Int, limit: Int, sortOrder: SortOrder) -> AnyPublisher<[Item], Error>
    func getItemsByNewsSite(newsSite: String, page: Int, limit: Int) -> AnyPublisher<[Item], Error>
    func saveLastLoadedItems(items: [Item])
    func getLastLoadedItems() -> [Item]?
}

// Specific repositories for different content types
protocol ArticleRepository: ContentRepository where Item == Article {}
protocol BlogRepository: ContentRepository where Item == Article {}
protocol ReportRepository: ContentRepository where Item == Article {}

// Repository for news sites
protocol NewsSiteRepository {
    func getNewsSites(contentType: ContentType) -> AnyPublisher<[String], Error>
}

// Repository for recent searches
protocol SearchRepository {
    func saveRecentSearch(query: String)
    func getRecentSearches() -> [String]
    func clearRecentSearches()
}

// Combined repository for all content types
protocol SpaceNewsRepository: ArticleRepository, BlogRepository, ReportRepository, NewsSiteRepository, SearchRepository {}

// MARK: - Repository Extensions

// Extension for ArticleRepository to add methods required by ContentLoadingUseCase
extension ArticleRepository {
    func getArticles(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        if let newsSite = newsSite {
            return getItemsByNewsSite(newsSite: newsSite, page: 1, limit: 50)
        } else {
            return getItems(page: 1, limit: 50, sortOrder: sortOrder)
        }
    }
    
    func loadMoreArticles(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        if let newsSite = newsSite {
            return getItemsByNewsSite(newsSite: newsSite, page: 2, limit: 50)
        } else {
            return getItems(page: 2, limit: 50, sortOrder: sortOrder)
        }
    }
    
    func refreshArticles(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return getArticles(newsSite: newsSite, sortOrder: sortOrder)
    }
}

// Extension for BlogRepository to add methods required by ContentLoadingUseCase
extension BlogRepository {
    func getBlogs(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        if let newsSite = newsSite {
            return getItemsByNewsSite(newsSite: newsSite, page: 1, limit: 50)
        } else {
            return getItems(page: 1, limit: 50, sortOrder: sortOrder)
        }
    }
    
    func loadMoreBlogs(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        if let newsSite = newsSite {
            return getItemsByNewsSite(newsSite: newsSite, page: 2, limit: 50)
        } else {
            return getItems(page: 2, limit: 50, sortOrder: sortOrder)
        }
    }
    
    func refreshBlogs(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return getBlogs(newsSite: newsSite, sortOrder: sortOrder)
    }
}

// Extension for ReportRepository to add methods required by ContentLoadingUseCase
extension ReportRepository {
    func getReports(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        if let newsSite = newsSite {
            return getItemsByNewsSite(newsSite: newsSite, page: 1, limit: 50)
        } else {
            return getItems(page: 1, limit: 50, sortOrder: sortOrder)
        }
    }
    
    func loadMoreReports(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        if let newsSite = newsSite {
            return getItemsByNewsSite(newsSite: newsSite, page: 2, limit: 50)
        } else {
            return getItems(page: 2, limit: 50, sortOrder: sortOrder)
        }
    }
    
    func refreshReports(newsSite: String?, sortOrder: SortOrder) -> AnyPublisher<[Article], Error> {
        return getReports(newsSite: newsSite, sortOrder: sortOrder)
    }
}

