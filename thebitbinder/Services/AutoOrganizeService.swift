//
//  AutoOrganizeService.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/7/25.
//

import Foundation
import SwiftData

class AutoOrganizeService {
    
    // MARK: - Default Categories
    
    static let defaultCategories = [
        "Relationships",
        "Work & Office",
        "Food & Cooking",
        "Travel & Places",
        "Observational",
        "Dark Humor"
    ]
    
    // MARK: - Get Categories
    
    static func getCategories() -> [String] {
        if let saved = UserDefaults.standard.array(forKey: "jokeCategories") as? [String] {
            return saved.isEmpty ? defaultCategories : saved
        }
        return defaultCategories
    }
    
    static func setCategories(_ categories: [String]) {
        UserDefaults.standard.set(categories, forKey: "jokeCategories")
    }
    
    // MARK: - Auto-Categorize Jokes
    
    static func categorizeJoke(_ joke: Joke) -> String? {
        let content = (joke.title + " " + joke.content).lowercased()
        let categories = getCategories()
        
        // Simple keyword matching based on categories
        for category in categories {
            if matchesCategory(content, category: category) {
                return category
            }
        }
        
        return nil // Return nil to let user choose
    }
    
    private static func matchesCategory(_ content: String, category: String) -> Bool {
        let categoryLower = category.lowercased()
        
        switch categoryLower {
        case "relationships":
            let keywords = ["boyfriend", "girlfriend", "husband", "wife", "marriage", "date", "love", "romance", "breakup", "partner", "dating", "kiss", "wedding"]
            return keywords.contains { content.contains($0) }
            
        case "work & office":
            let keywords = ["boss", "employee", "manager", "office", "work", "job", "interview", "meeting", "coworker", "promotion", "fired"]
            return keywords.contains { content.contains($0) }
            
        case "food & cooking":
            let keywords = ["food", "eat", "dinner", "lunch", "breakfast", "cook", "restaurant", "pizza", "burger", "steak", "cake", "beer", "wine"]
            return keywords.contains { content.contains($0) }
            
        case "travel & places":
            let keywords = ["travel", "vacation", "airport", "hotel", "beach", "mountain", "trip", "flight", "tourist", "country", "city"]
            return keywords.contains { content.contains($0) }
            
        case "dark humor":
            let keywords = ["death", "dying", "dead", "kill", "suicide", "dark", "evil", "hell", "damn"]
            return keywords.contains { content.contains($0) }
            
        default:
            return false
        }
    }
    
    // MARK: - Organize Jokes
    
    static func organizeJoke(
        _ joke: Joke,
        intoCategory categoryName: String,
        existingFolders: [JokeFolder],
        modelContext: ModelContext
    ) {
        var targetFolder = existingFolders.first { $0.name == categoryName }
        
        if targetFolder == nil {
            targetFolder = JokeFolder(name: categoryName)
            modelContext.insert(targetFolder!)
        }
        
        joke.folder = targetFolder
        print("✅ Organized '\(joke.title)' into '\(categoryName)'")
    }
}
