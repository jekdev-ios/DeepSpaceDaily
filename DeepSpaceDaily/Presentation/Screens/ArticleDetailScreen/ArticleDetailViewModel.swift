//
//  ArticleDetailViewModel.swift
//  DeepSpaceDaily
//
//  Created by admin on 28/02/25.
//

import Foundation
import Combine

class ArticleDetailViewModel: ObservableObject {
    // MARK: - Dependencies
    private let manageSessionUseCase: ManageSessionUseCase
    
    // MARK: - Published Properties
    @Published var article: Article
    @Published var formattedDate: String = ""
    @Published var summary: String = ""
    @Published var isShowingFullSummary: Bool = false
    
    // MARK: - Initialization
    
    init(
        article: Article,
        manageSessionUseCase: ManageSessionUseCase = DependencyInjection.shared.manageSessionUseCase
    ) {
        self.article = article
        self.manageSessionUseCase = manageSessionUseCase
        
        formatDate()
        updateSummary()
    }
    
    // MARK: - Public Methods
    
    func resetSession() {
        manageSessionUseCase.resetSession()
    }
    
    func toggleSummary() {
        isShowingFullSummary.toggle()
        updateSummary()
    }
    
    // MARK: - Private Methods
    
    private func formatDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = dateFormatter.date(from: article.publishedAt) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "MMMM d, yyyy, HH:mm"
            outputFormatter.locale = Locale.current
            
            formattedDate = outputFormatter.string(from: date)
        } else {
            formattedDate = article.publishedAt
        }
    }
    
    private func updateSummary() {
        // Clean up the text by removing newlines and extra spaces
        let cleanSummary = article.summary
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\\n", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if isShowingFullSummary {
            summary = cleanSummary
        } else {
            // Extract the first sentence from the summary
            if let firstSentenceEnd = cleanSummary.firstIndex(of: ".") {
                let firstSentence = cleanSummary[..<firstSentenceEnd]
                summary = String(firstSentence) + "."
            } else {
                summary = cleanSummary
            }
        }
    }
} 
