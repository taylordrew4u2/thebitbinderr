//
//  AutoOrganizeService.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/7/25.
//

import Foundation
import SwiftData

class AutoOrganizeService {
    
    // MARK: - Simple Categories
    
    static let defaultCategories = [
        "Relationships",
        "Work & Office",
        "Food & Cooking",
        "Travel & Places",
        "Observational",
        "Dark Humor"
    ]
    
    // Simple keyword lists for each category
    private static let categoryKeywords: [String: [String]] = [
        "Relationships": ["boyfriend", "girlfriend", "husband", "wife", "marriage", "dating", "love", "romance", "breakup", "divorce", "relationship", "partner"],
        "Work & Office": ["boss", "employee", "manager", "office", "work", "job", "interview", "meeting", "deadline", "coworker", "workplace", "fired"],
        "Food & Cooking": ["food", "eat", "dinner", "lunch", "breakfast", "cook", "restaurant", "pizza", "burger", "cake", "dessert", "drink", "chef", "meal"],
        "Travel & Places": ["travel", "trip", "vacation", "plane", "airport", "hotel", "beach", "destination", "road trip", "tourist", "explore", "visiting"],
        "Observational": ["people", "society", "culture", "behavior", "habit", "human", "life", "funny", "noticed", "thing"],
        "Dark Humor": ["death", "kill", "die", "dark", "evil", "hell", "zombie", "horror", "scary", "blood", "suffering"]
    ]
    
    // MARK: - Get Categories
    
    static func getCategories() -> [String] {
        return defaultCategories
    }
    
    static func getUserCategories() -> [String] {
        if let saved = UserDefaults.standard.array(forKey: "JokeCategories") as? [String] {
            return saved
        }
        return defaultCategories
    }
    
    static func saveUserCategories(_ categories: [String]) {
        UserDefaults.standard.set(categories, forKey: "JokeCategories")
    }
    
    // MARK: - Add/Remove Categories
    
    static func addCategory(_ category: String) {
        var categories = getUserCategories()
        if !categories.contains(category) {
            categories.append(category)
            saveUserCategories(categories)
        }
    }
    
    static func removeCategory(_ category: String) {
        var categories = getUserCategories()
        categories.removeAll { $0 == category }
        saveUserCategories(categories)
    }
    
    // MARK: - Categorization
    
    /// Suggests categories for a joke based on keywords
    static func suggestCategories(for joke: Joke) -> [(category: String, confidence: Double)] {
        let text = (joke.title + " " + joke.content).lowercased()
        var suggestions: [(category: String, confidence: Double)] = []
        
        for category in getUserCategories() {
            let keywords = categoryKeywords[category] ?? []
            var matchCount = 0
            
            for keyword in keywords {
                if text.contains(keyword) {
                    matchCount += 1
                }
            }
            
            if matchCount > 0 {
                // Calculate confidence based on matches (max 1.0)
                let confidence = min(Double(matchCount) / 3.0, 1.0)
                suggestions.append((category: category, confidence: confidence))
            }
        }
        
        // Sort by confidence
        suggestions.sort(by: { $0.confidence > $1.confidence })
        
        return suggestions
    }
    
    /// Auto-organizes a joke if there's high confidence (3+ keyword matches)
    static func autoCategorize(_ joke: Joke) -> String? {
        let suggestions = suggestCategories(for: joke)
        
        // Only auto-categorize if we have 3+ matches (high confidence)
        if let topSuggestion = suggestions.first, topSuggestion.confidence >= 1.0 {
            return topSuggestion.category
        }
        
        return nil
    }
    
    /// Auto-organizes multiple jokes with feedback
    static func autoOrganizeAll(
        jokes: [Joke],
        folders: [JokeFolder],
        modelContext: ModelContext
    ) -> (organized: Int, suggested: Int) {
        var organizedCount = 0
        var suggestedCount = 0
        var folderMap: [String: JokeFolder] = [:]
        
        // Create folder lookup
        for folder in folders {
            folderMap[folder.name] = folder
        }
        
        for joke in jokes {
            if let category = autoCategorize(joke) {
                // Get or create folder
                if folderMap[category] == nil {
                    let newFolder = JokeFolder(name: category)
                    modelContext.insert(newFolder)
                    folderMap[category] = newFolder
                }
                
                joke.folder = folderMap[category]
                organizedCount += 1
            } else {
                suggestedCount += 1
            }
        }
        
        return (organizedCount, suggestedCount)
    }
}
