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
        "Work & Career",
        "Food & Dining",
        "Travel",
        "Family",
        "Observational"
    ]
    
    // MARK: - Category Management
    
    static func getCategories() -> [String] {
        if let saved = UserDefaults.standard.array(forKey: "jokeCategories") as? [String], !saved.isEmpty {
            return saved
        }
        return defaultCategories
    }
    
    static func setCategories(_ categories: [String]) {
        UserDefaults.standard.set(categories, forKey: "jokeCategories")
    }
    
    static func addCategory(_ category: String) {
        var categories = getCategories()
        if !categories.contains(category) {
            categories.append(category)
            setCategories(categories)
        }
    }
    
    static func removeCategory(_ category: String) {
        var categories = getCategories()
        categories.removeAll { $0 == category }
        setCategories(categories)
    }
    
    // MARK: - Smart Categorization
    
    /// Suggests up to 3 best matching categories for a joke with confidence scores
    static func suggestCategories(for joke: Joke) -> [(category: String, confidence: Int)] {
        let content = (joke.title + " " + joke.content).lowercased()
        let categories = getCategories()
        var scores: [(String, Int)] = []
        
        for category in categories {
            let score = calculateMatchScore(content: content, category: category)
            if score > 0 {
                scores.append((category, score))
            }
        }
        
        // Sort by score and return top 3
        return scores.sorted { $0.1 > $1.1 }.prefix(3).map { ($0.0, $0.1) }
    }
    
    /// Automatically categorizes a joke (returns nil if confidence is too low)
    static func autoCategorize(_ joke: Joke) -> String? {
        let suggestions = suggestCategories(for: joke)
        // Only auto-categorize if confidence is high (>= 3 keyword matches)
        if let best = suggestions.first, best.confidence >= 3 {
            return best.category
        }
        return nil
    }
    
    private static func calculateMatchScore(content: String, category: String) -> Int {
        let keywords = getKeywords(for: category)
        var score = 0
        
        for keyword in keywords {
            if content.contains(keyword) {
                score += 1
                // Bonus for exact word match (not just substring)
                let words = content.components(separatedBy: .whitespacesAndNewlines)
                if words.contains(keyword) {
                    score += 1
                }
            }
        }
        
        return score
    }
    
    private static func getKeywords(for category: String) -> [String] {
        let categoryLower = category.lowercased()
        
        // Built-in keyword sets for common categories
        switch categoryLower {
        case let c where c.contains("relationship") || c.contains("dating") || c.contains("love"):
            return ["boyfriend", "girlfriend", "husband", "wife", "marriage", "date", "dating", "love", "romance", "breakup", "partner", "kiss", "wedding", "tinder", "ex"]
            
        case let c where c.contains("work") || c.contains("career") || c.contains("job") || c.contains("office"):
            return ["boss", "employee", "manager", "office", "work", "job", "interview", "meeting", "coworker", "colleague", "fired", "quit", "promotion", "salary", "career"]
            
        case let c where c.contains("food") || c.contains("cook") || c.contains("restaurant") || c.contains("dining"):
            return ["food", "eat", "dinner", "lunch", "breakfast", "cook", "restaurant", "pizza", "burger", "steak", "cake", "beer", "wine", "chef", "menu", "waiter"]
            
        case let c where c.contains("travel") || c.contains("vacation") || c.contains("trip"):
            return ["travel", "vacation", "airport", "hotel", "beach", "trip", "flight", "tourist", "passport", "plane", "visit"]
            
        case let c where c.contains("family") || c.contains("parent") || c.contains("kid"):
            return ["mom", "dad", "mother", "father", "parent", "kid", "kids", "child", "children", "family", "baby", "son", "daughter"]
            
        case let c where c.contains("tech") || c.contains("computer") || c.contains("phone"):
            return ["computer", "phone", "app", "internet", "tech", "coding", "programmer", "software", "iphone", "android", "wifi"]
            
        case let c where c.contains("animal") || c.contains("pet"):
            return ["dog", "cat", "pet", "animal", "puppy", "kitten", "bird", "fish"]
            
        case let c where c.contains("dark"):
            return ["death", "die", "dead", "kill", "murder", "dark", "evil", "hell"]
            
        case let c where c.contains("sport") || c.contains("gym") || c.contains("fitness"):
            return ["sport", "football", "basketball", "soccer", "baseball", "gym", "workout", "exercise", "game", "team"]
            
        default:
            // For custom categories, return empty (user will manually categorize)
            return []
        }
    }
    
    // MARK: - Organization Actions
    
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
    }
    
    /// Bulk organize jokes with smart categorization
    static func organizeAllJokes(
        _ jokes: [Joke],
        existingFolders: [JokeFolder],
        modelContext: ModelContext
    ) -> (organized: Int, needsReview: Int) {
        var organized = 0
        var needsReview = 0
        
        for joke in jokes {
            if let category = autoCategorize(joke) {
                organizeJoke(joke, intoCategory: category, existingFolders: existingFolders, modelContext: modelContext)
                organized += 1
            } else {
                needsReview += 1
            }
        }
        
        return (organized, needsReview)
    }
}
