//
//  ContentType.swift
//  DeepSpaceDaily
//
//  Created by admin on 29/02/25.
//

import Foundation

enum ContentType: String, CaseIterable {
    case articles = "articles"
    case blogs = "blogs"
    case reports = "reports"
    
    var displayName: String {
        rawValue.capitalized
    }
}