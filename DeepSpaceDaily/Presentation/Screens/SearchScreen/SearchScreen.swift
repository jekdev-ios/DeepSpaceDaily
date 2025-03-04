//
//  SearchScreen.swift
//  DeepSpaceDaily
//
//  Created by admin on 28/02/25.
//

import SwiftUI

struct SearchScreen: View {
    @StateObject private var viewModel = SearchViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    private var secondaryBackgroundColor: Color {
        colorScheme == .dark ? Color(UIColor.systemGray6) : Color(UIColor.systemGray6)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Header
            VStack(spacing: 12) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search space news", text: $viewModel.searchQuery)
                        .autocapitalization(.none)
                        .textFieldStyle(PlainTextFieldStyle())
                        .submitLabel(.search)
                        .onSubmit {
                            viewModel.search()
                        }
                    
                    if !viewModel.searchQuery.isEmpty {
                        Button(action: {
                            viewModel.searchQuery = ""
                            viewModel.search()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button(action: {
                        viewModel.search()
                    }) {
                        Text("Search")
                            .foregroundColor(.blue)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.leading, 8)
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Recent Searches Pills
                if !viewModel.recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Recent Searches")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            Button(action: {
                                viewModel.clearRecentSearches()
                            }) {
                                Text("Clear")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.recentSearches, id: \.self) { search in
                                    Button(action: {
                                        viewModel.selectRecentSearch(search)
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "clock")
                                                .font(.system(size: 12))
                                            Text(search)
                                                .font(.subheadline)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(secondaryBackgroundColor)
                                        .foregroundColor(.primary)
                                        .cornerRadius(16)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            
            // Content Area
            if !viewModel.searchResults.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.searchResults) { article in
                            NavigationLink(destination: ArticleDetailScreen(article: article)) {
                                EnhancedArticleCard(article: article)
                                    .padding(.horizontal)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical)
                }
            } else if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if !viewModel.searchQuery.isEmpty && viewModel.searchResults.isEmpty && !viewModel.isLoading {
                Spacer()
                Text("No results found")
                    .font(.headline)
                    .foregroundColor(.gray)
                Spacer()
            } else {
                Spacer()
                Text("Search for space news")
                    .font(.headline)
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
} 
