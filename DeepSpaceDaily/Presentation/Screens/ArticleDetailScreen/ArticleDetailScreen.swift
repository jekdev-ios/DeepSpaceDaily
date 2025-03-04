//
//  ArticleDetailScreen.swift
//  DeepSpaceDaily
//
//  Created by admin on 28/02/25.
//

import SwiftUI

struct ArticleDetailScreen: View {
    @StateObject private var viewModel: ArticleDetailViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    private var primaryColor: Color {
        colorScheme == .dark ? Color.indigo : Color.blue
    }
    
    init(article: Article) {
        _viewModel = StateObject(wrappedValue: ArticleDetailViewModel(article: article))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Hero Image Section
            ArticleHeroImage(imageUrl: viewModel.article.imageUrl)
            
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Main Content Section
                        VStack(alignment: .leading, spacing: 16) {
                            // Title and Provider
                            ArticleHeader(
                                title: viewModel.article.title,
                                newsSite: viewModel.article.newsSite,
                                date: viewModel.formattedDate,
                                primaryColor: primaryColor
                            )
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            // Summary Section
                            ArticleSummary(
                                summary: viewModel.summary,
                                isShowingFullSummary: viewModel.isShowingFullSummary,
                                primaryColor: primaryColor,
                                onToggleSummary: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.toggleSummary()
                                    }
                                }
                            )
                            
                            // Related Information
                            RelatedInformation(
                                launches: viewModel.article.launches,
                                events: viewModel.article.events
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                }
                
                // Bottom Action Button
                ReadFullArticleButton(
                    url: viewModel.article.url,
                    primaryColor: primaryColor
                )
            }
        }
        .ignoresSafeArea(.all, edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if !viewModel.article.newsSite.isEmpty {
                    Text(viewModel.article.newsSite)
                        .font(.headline)
                }
            }
        }
        .onAppear {
            viewModel.resetSession()
        }
    }
} 