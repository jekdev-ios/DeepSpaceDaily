//
//  ArticleCards.swift
//  DeepSpaceDaily
//
//  Created by admin on 29/02/25.
//

import SwiftUI

// MARK: - Featured Article Card
struct FeaturedArticleCard: View {
    let article: Article
    @Environment(\.colorScheme) private var colorScheme
    
    // Date formatter for parsing ISO dates
    private let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()
    
    // Date formatter for display
    private let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Article Image with LazyImage
            LazyImageView(url: URL(string: article.imageUrl), contentMode: .fill)
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Article Content
            VStack(alignment: .leading, spacing: 8) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(article.description ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                HStack {
                    Text(article.source ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatDate(article.publishedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .background(cardBackgroundColor)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
    
    private func formatDate(_ dateString: String) -> String {
        guard let date = isoDateFormatter.date(from: dateString) else {
            return dateString
        }
        return displayDateFormatter.string(from: date)
    }
}

// MARK: - Compact Article Card
struct CompactArticleCard: View {
    let article: Article
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Article Image with LazyImage
            LazyImageView(url: URL(string: article.imageUrl), contentMode: .fill)
            .frame(width: 125, height: 75)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Article Title
            Text(article.title)
                .font(.body)
                .fontWeight(.bold)
                .lineLimit(2)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
} 
