//
//  Article.swift
//  DeepSpaceDaily
//
//  Created by admin on 28/02/25.
//

import Foundation

struct Article: Identifiable, Codable {
    let id: Int?
    let title: String
    let url: String
    let imageUrl: String
    let newsSite: String
    let summary: String
    let publishedAt: String
    let updatedAt: String
    let featured: Bool?
    let launches: [Launch]?
    let events: [Event]?
    let authors: [Author]?
    let description: String?
    let source: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, url, summary, featured, launches, events, authors, description, source
        case imageUrl = "image_url"
        case newsSite = "news_site"
        case publishedAt = "published_at"
        case updatedAt = "updated_at"
    }
}

struct Author: Codable {
    let name: String
    let socials: Socials?
}

struct Socials: Codable {
    let x: String?
    let youtube: String?
    let instagram: String?
    let linkedin: String?
    let mastodon: String?
    let bluesky: String?
}

struct Launch: Identifiable, Codable {
    let id: String
    let provider: String
    
    enum CodingKeys: String, CodingKey {
        case id = "launch_id"
        case provider
    }
}

struct Event: Identifiable, Codable {
    let id: Int
    let provider: String
    
    enum CodingKeys: String, CodingKey {
        case id = "event_id"
        case provider
    }
}

struct ArticleResponse: Codable {
    let results: [Article]
    let count: Int
    let next: String?
    let previous: String?
}
