//
//  ArticleListScreen.swift
//  DeepSpaceDaily
//
//  Created by admin on 29/02/25.
//

import SwiftUI

struct ArticleListScreen: View {
    let type: ContentType
    @StateObject private var viewModel = HomeViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    // Date formatter for parsing ISO dates
    private let dateFormatter: DateFormatter = {
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
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(UIColor.systemBackground)
    }
    
    private var secondaryBackgroundColor: Color {
        colorScheme == .dark ? Color(UIColor.systemGray6) : Color(UIColor.systemGray6)
    }
    
    private var primaryColor: Color {
        colorScheme == .dark ? Color.indigo : Color.blue
    }
    
    private var filteredArticles: [Article] {
        guard let articles = viewModel.contentByType[type] else { return [] }
        
        // First filter by news site if needed
        let filtered = if let selectedSite = viewModel.selectedNewsSite {
            articles.filter { $0.newsSite == selectedSite }
        } else {
            articles
        }
        // Then sort by date
        return filtered.sorted { first, second in
            guard let firstDate = dateFormatter.date(from: first.publishedAt),
                  let secondDate = dateFormatter.date(from: second.publishedAt) else {
                return false
            }
            
            return viewModel.sortOrder == .ascending ? firstDate < secondDate : firstDate > secondDate
        }
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Filter Options
                HStack(spacing: 12) {
                    // News Site Filter
                    Menu {
                        Button("All News Sites") {
                            viewModel.selectNewsSite(nil)
                        }
                        
                        ForEach(viewModel.newsSites, id: \.self) { site in
                            Button(site) {
                                viewModel.selectNewsSite(site)
                            }
                        }
                    } label: {
                        HStack {
                            if viewModel.isSorting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                                    .scaleEffect(0.7)
                                    .frame(width: 12, height: 12)
                            } else {
                                Image(systemName: "newspaper")
                                    .font(.system(size: 12))
                            }
                            Text(viewModel.selectedNewsSite ?? "All Sites")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(secondaryBackgroundColor)
                        .cornerRadius(20)
                        .opacity(viewModel.isSorting ? 0.7 : 1.0)
                    }
                    .disabled(viewModel.isSorting || viewModel.isLoading)
                    
                    // Sort Order
                    Button(action: viewModel.toggleSortOrder) {
                        HStack {
                            if viewModel.isSorting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                                    .scaleEffect(0.7)
                                    .frame(width: 12, height: 12)
                            } else {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 12))
                            }
                            Text(viewModel.sortOrder == .ascending ? "Oldest" : "Newest")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(secondaryBackgroundColor)
                        .cornerRadius(20)
                        .opacity(viewModel.isSorting ? 0.7 : 1.0)
                    }
                    .disabled(viewModel.isSorting || viewModel.isLoading)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                ScrollView {
                    if viewModel.isLoading || viewModel.isSorting {
                        VStack(spacing: 16) {
                            ForEach(0..<5) { _ in
                                ArticleSkeletonLoader()
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    } else {
                        LazyVStack(spacing: 16) {
                            if !filteredArticles.isEmpty {
                                ForEach(filteredArticles) { article in
                                    NavigationLink(destination: ArticleDetailScreen(article: article)) {
                                        EnhancedArticleCard(article: article)
                                            .padding(.horizontal)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "newspaper")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    Text("No articles found")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    if let selectedSite = viewModel.selectedNewsSite {
                                        Text("Try selecting a different news site")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.top, 40)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .refreshable {
                viewModel.loadArticles()
                viewModel.reloadNewsSites()
            }
        }
        .navigationTitle(type.displayName)
        .onAppear {
            viewModel.resetSession()
            viewModel.setContentType(type)
            viewModel.loadArticles()
        }
    }
}

// MARK: - Enhanced Article Card
struct EnhancedArticleCard: View {
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
        HStack(alignment: .top, spacing: 12) {
            // Article Image
            VStack(alignment: .leading){
                LazyImageView(url: URL(string: article.imageUrl), contentMode: .fill)
                .frame(width: 175, height: 125)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                HStack {
                    
                    if let launches = article.launches?.first?.id {
                        Text(launches)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                    
                    if let events = article.events?.first?.id {
                        Text("\(events)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    Text(formatDate(article.publishedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Article Details
            VStack(alignment: .leading, spacing: 6) {
                // News Site and Date
                    Text(article.newsSite)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                // Title
                Text(article.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                // Summary
                Text(article.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Launches and Events
                let hasLaunches = article.launches != nil && !article.launches!.isEmpty
                let hasEvents = article.events != nil && !article.events!.isEmpty
                
                if hasLaunches || hasEvents {
                    HStack(spacing: 8) {
                        if let launches = article.launches, !launches.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "rocket")
                                    .font(.system(size: 10))
                                Text("\(launches.count)")
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                        }
                        
                        if let events = article.events, !events.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 10))
                                Text("\(events.count)")
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(12)
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ dateString: String) -> String {
        guard let date = isoDateFormatter.date(from: dateString) else {
            return ""
        }
        
        return displayDateFormatter.string(from: date)
    }
}

// MARK: - Article Skeleton Loader
struct ArticleSkeletonLoader: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white
    }
    
    private var skeletonColor: Color {
        colorScheme == .dark ? Color(UIColor.systemGray5) : Color(UIColor.systemGray5)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Image placeholder
            Rectangle()
                .fill(skeletonColor)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shimmering()
            
            // Content placeholders
            VStack(alignment: .leading, spacing: 8) {
                // Title placeholder
                Rectangle()
                    .fill(skeletonColor)
                    .frame(height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shimmering()
                
                // Short line placeholder
                Rectangle()
                    .fill(skeletonColor)
                    .frame(width: 120, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shimmering()
                
                Spacer()
                
                // Bottom row placeholders
                HStack {
                    // Date placeholder
                    Rectangle()
                        .fill(skeletonColor)
                        .frame(width: 80, height: 14)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .shimmering()
                    
                    Spacer()
                    
                    // News site placeholder
                    Rectangle()
                        .fill(skeletonColor)
                        .frame(width: 60, height: 14)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .shimmering()
                }
            }
            .frame(height: 100)
        }
        .padding(12)
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Shimmering Effect
extension View {
    func shimmering() -> some View {
        self.modifier(ShimmeringEffect())
    }
}

struct ShimmeringEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.3), location: 0.3),
                            .init(color: .white.opacity(0.5), location: 0.5),
                            .init(color: .white.opacity(0.3), location: 0.7),
                            .init(color: .clear, location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: -geo.size.width + (geo.size.width * 2) * phase)
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    self.phase = 1
                }
            }
    }
} 
