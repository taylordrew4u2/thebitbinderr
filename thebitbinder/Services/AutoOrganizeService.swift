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
        "Observational",
        "Dark Humor",
        "Sports",
        "Technology",
        "Health",
        "Money",
        "School",
        "Animals",
        "Other"
    ]
    
    // Keywords for each category (simple matching)
    private static let categoryKeywords: [String: [String]] = [
        "Relationships": ["boyfriend", "girlfriend", "husband", "wife", "marriage", "dating", "love", "romance", "breakup", "divorce", "relationship", "partner", "ex", "date", "kiss", "wedding"],
        "Work & Career": ["boss", "employee", "manager", "office", "work", "job", "interview", "meeting", "deadline", "coworker", "workplace", "fired", "salary", "promotion", "company"],
        "Food & Dining": ["food", "eat", "dinner", "lunch", "breakfast", "cook", "restaurant", "pizza", "burger", "cake", "dessert", "drink", "chef", "meal", "hungry", "kitchen"],
        "Travel": ["travel", "trip", "vacation", "plane", "airport", "hotel", "beach", "tourist", "flight", "road trip", "visited", "destination"],
        "Family": ["mom", "dad", "mother", "father", "brother", "sister", "son", "daughter", "kid", "kids", "child", "family", "parent", "grandma", "grandpa", "baby"],
        "Observational": ["people", "society", "everyone", "nobody", "always", "never", "why do", "have you noticed", "isn't it funny", "the thing about"],
        "Dark Humor": ["death", "die", "dead", "funeral", "kill", "dark", "hell", "devil", "ghost", "scary", "horror", "blood"],
        "Sports": ["football", "basketball", "soccer", "baseball", "hockey", "tennis", "golf", "gym", "workout", "exercise", "coach", "team", "game", "player"],
        "Technology": ["computer", "phone", "internet", "app", "software", "programmer", "code", "tech", "robot", "ai", "wifi", "social media"],
        "Health": ["doctor", "hospital", "medicine", "sick", "health", "nurse", "surgery", "pain", "therapy", "diet", "fitness"],
        "Money": ["money", "cash", "dollar", "rich", "poor", "broke", "bank", "credit", "debt", "expensive", "cheap", "budget", "tax"],
        "School": ["school", "college", "university", "student", "teacher", "professor", "class", "test", "exam", "homework", "grade"],
        "Animals": ["dog", "cat", "bird", "fish", "animal", "pet", "horse", "cow", "chicken", "pig", "bear", "lion"],
        "Other": []
    ]
    
    // MARK: - User Category Management
    
    static func getUserCategories() -> [String] {
        if let saved = UserDefaults.standard.array(forKey: "JokeCategories") as? [String], !saved.isEmpty {
            return saved
        }
        return defaultCategories
    }
    
    static func saveUserCategories(_ categories: [String]) {
        UserDefaults.standard.set(categories, forKey: "JokeCategories")
    }
    
    static func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: "JokeCategories")
    }
    
    static func addCategory(_ category: String) {
        var categories = getUserCategories()
        let trimmed = category.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !categories.contains(trimmed) {
            categories.append(trimmed)
            saveUserCategories(categories)
        }
    }
    
    static func removeCategory(_ category: String) {
        var categories = getUserCategories()
        categories.removeAll { $0 == category }
        saveUserCategories(categories)
    }
    
    static func reorderCategories(_ categories: [String]) {
        saveUserCategories(categories)
    }
    
    // MARK: - Auto-Organize ALL Jokes
    
    /// Finds the best category for a joke based on keyword matching
    static func findBestCategory(for joke: Joke, using categories: [String]) -> String {
        let text = (joke.title + " " + joke.content).lowercased()
        
        var bestCategory = "Other"
        var bestMatchCount = 0
        
        for category in categories {
            let keywords = categoryKeywords[category] ?? []
            var matchCount = 0
            
            for keyword in keywords {
                if text.contains(keyword.lowercased()) {
                    matchCount += 1
                }
            }
            
            if matchCount > bestMatchCount {
                bestMatchCount = matchCount
                bestCategory = category
            }
        }
        
        // If no matches found and "Other" isn't in categories, use first category
        if bestMatchCount == 0 {
            if categories.contains("Other") {
                return "Other"
            } else {
                return categories.first ?? "Other"
            }
        }
        
        return bestCategory
    }
    
    /// Auto-organizes ALL jokes (not just unorganized ones)
    static func organizeAllJokes(
        jokes: [Joke],
        categories: [String],
        folders: [JokeFolder],
        modelContext: ModelContext
    ) -> Int {
        var organizedCount = 0
        var folderMap: [String: JokeFolder] = [:]
        
        // Build folder lookup
        for folder in folders {
            folderMap[folder.name] = folder
        }
        
        // Create folders for categories that don't exist
        for category in categories {
            if folderMap[category] == nil {
                let newFolder = JokeFolder(name: category)
                modelContext.insert(newFolder)
                folderMap[category] = newFolder
            }
        }
        
        // Organize each joke
        for joke in jokes {
            let bestCategory = findBestCategory(for: joke, using: categories)
            
            if let folder = folderMap[bestCategory] {
                joke.folder = folder
                organizedCount += 1
            }
        }
        
        try? modelContext.save()
        return organizedCount
    }
}
