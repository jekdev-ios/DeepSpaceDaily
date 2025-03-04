//
//  ArticleDetailComponents.swift
//  DeepSpaceDaily
//
//  Created by admin on 29/02/25.
//

import SwiftUI

// MARK: - Hero Image Section
struct ArticleHeroImage: View {
    let imageUrl: String
    
    var body: some View {
        if !imageUrl.isEmpty {
            LazyImageView(url: URL(string: imageUrl), contentMode: .fill)
            .frame(height: 250)
            .clipped()
        }
    }
}

// MARK: - Article Header
struct ArticleHeader: View {
    let title: String
    let newsSite: String
    let date: String
    let primaryColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .lineSpacing(4)
            
            if !newsSite.isEmpty {
                HStack {
                    Text(newsSite)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(primaryColor)
                    
                    if !date.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Article Summary
struct ArticleSummary: View {
    let summary: String
    let isShowingFullSummary: Bool
    let primaryColor: Color
    let onToggleSummary: () -> Void
    
    var body: some View {
        if !summary.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("About This Article")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(summary)
                    .font(.body)
                    .lineSpacing(6)
                    .foregroundColor(.secondary)
                
                if summary.contains(".") {
                    Button(action: onToggleSummary) {
                        HStack(spacing: 4) {
                            Text(isShowingFullSummary ? "Show Less" : "Read More")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Image(systemName: isShowingFullSummary ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(primaryColor)
                    }
                }
            }
        }
    }
}

// MARK: - Related Information
struct RelatedInformation: View {
    let launches: [Launch]?
    let events: [Event]?
    
    var body: some View {
        if let launches = launches,
           let events = events,
           !launches.isEmpty || !events.isEmpty {
            
            Divider()
                .padding(.vertical, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Related Information")
                    .font(.headline)
                
                if !launches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Launches")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ForEach(launches) { launch in
                            HStack(spacing: 12) {
                                Image(systemName: "rocket.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 16))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(launch.provider)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("ID: \(launch.id)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                
                if !events.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Events")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ForEach(events) { event in
                            HStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.provider)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("ID: \(event.id)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Read Full Article Button
struct ReadFullArticleButton: View {
    let url: String
    let primaryColor: Color
    
    var body: some View {
        if !url.isEmpty {
            VStack(spacing: 0) {
                Divider()
                
                Link(destination: URL(string: url)!) {
                    HStack(spacing: 8) {
                        Text("Read Full Article")
                            .font(.headline)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(primaryColor)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(UIColor.systemBackground))
        }
    }
} 