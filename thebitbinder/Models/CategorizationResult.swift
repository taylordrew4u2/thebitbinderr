//
//  CategorizationResult.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/8/25.
//

import Foundation
import SwiftData

// MARK: - Category Matching Result
struct CategoryMatch: Codable {
    var category: String
    var confidence: Double  // 0.0 to 1.0
    var reasoning: String
    var matchedKeywords: [String]
    
    // Metadata fields used by AutoOrganizeService
    var styleTags: [String]
    var emotionalTone: String?
    var craftSignals: [String]
    var structureScore: Double?
    
    var confidencePercent: String {
        String(format: "%.0f%%", confidence * 100)
    }
}

// MARK: - User Feedback for Better Categorization
@Model
final class CategorizationFeedback {
    var id: UUID
    var jokeId: UUID
    var suggestedCategory: String
    var userApproved: Bool
    var userProvidedCategory: String?
    var dateRecorded: Date
    
    init(jokeId: UUID, suggestedCategory: String, userApproved: Bool = false, userProvidedCategory: String? = nil) {
        self.id = UUID()
        self.jokeId = jokeId
        self.suggestedCategory = suggestedCategory
        self.userApproved = userApproved
        self.userProvidedCategory = userProvidedCategory
        self.dateRecorded = Date()
    }
}
