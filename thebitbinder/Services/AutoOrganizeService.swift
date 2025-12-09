//
//  AutoOrganizeService.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/7/25.
//

import Foundation
import SwiftData

// MARK: - Categorization Result

struct CategorizationResult {
    let category: String
    let confidence: String
    let matchedKeywords: [String]
    let reasoning: String
}

class AutoOrganizeService {
    
    // MARK: - Fewer Default Categories (6 core + Other)
    
    static let defaultCategories = [
        "Relationships",
        "Work",
        "Family",
        "Observational",
        "Dark Humor",
        "Other"
    ]
    
    // MARK: - Smart Keywords (expanded for better matching)
    
    private static let categoryKeywords: [String: [String]] = [
        "Relationships": [
            // Dating & Romance
            "boyfriend", "girlfriend", "husband", "wife", "spouse", "partner",
            "marriage", "married", "wedding", "engaged", "engagement",
            "dating", "date", "tinder", "bumble", "swipe",
            "love", "romance", "romantic", "kiss", "kissing",
            "breakup", "broke up", "divorce", "divorced", "ex",
            "relationship", "couple", "anniversary",
            "cheating", "affair", "flirt", "crush", "single"
        ],
        "Work": [
            // Job & Career
            "boss", "manager", "employee", "coworker", "colleague",
            "office", "workplace", "cubicle", "desk", "meeting",
            "work", "working", "job", "career", "profession",
            "interview", "resume", "hired", "fired", "quit",
            "salary", "paycheck", "raise", "promotion", "demoted",
            "deadline", "project", "presentation", "email", "emails",
            "monday", "friday", "weekend", "commute", "commuting",
            // Money (combined)
            "money", "cash", "dollar", "rich", "poor", "broke",
            "bank", "credit", "debt", "expensive", "cheap", "budget", "tax"
        ],
        "Family": [
            // Parents
            "mom", "mother", "dad", "father", "parent", "parents",
            // Siblings
            "brother", "sister", "sibling", "siblings",
            // Children
            "son", "daughter", "kid", "kids", "child", "children",
            "baby", "babies", "toddler", "teenager", "teen",
            // Extended family
            "grandma", "grandmother", "grandpa", "grandfather", "grandparent",
            "uncle", "aunt", "cousin", "in-law", "in-laws",
            "family", "relative", "relatives", "reunion"
        ],
        "Observational": [
            // Common phrases
            "people", "everyone", "nobody", "somebody", "anybody",
            "always", "never", "sometimes", "every time",
            "why do", "why does", "why is", "why are",
            "have you noticed", "you know what", "isn't it",
            "the thing about", "the problem with",
            // Life situations
            "life", "society", "world", "human", "humans",
            "weird", "strange", "funny thing", "crazy",
            // Common topics
            "phone", "internet", "social media", "instagram", "facebook", "twitter",
            "gym", "workout", "exercise", "diet", "eating",
            "doctor", "hospital", "sick", "health",
            "school", "college", "student", "teacher",
            "travel", "vacation", "airport", "plane", "hotel",
            "restaurant", "food", "eating", "dinner", "lunch",
            "dog", "cat", "pet", "animal"
        ],
        "Dark Humor": [
            // Death & Morbid
            "death", "dead", "die", "dying", "died",
            "kill", "killed", "murder", "funeral", "grave", "coffin",
            // Horror
            "ghost", "zombie", "demon", "devil", "hell", "satan",
            "scary", "horror", "haunted", "curse", "cursed",
            // Violence
            "blood", "bleeding", "pain", "suffer", "suffering", "torture",
            "crime", "criminal", "prison", "jail",
            // Dark themes
            "dark", "evil", "twisted", "messed up", "disturbing",
            "suicide", "depression", "depressed", "anxiety", "therapy"
        ],
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
            // Insert before "Other" if it exists
            if let otherIndex = categories.firstIndex(of: "Other") {
                categories.insert(trimmed, at: otherIndex)
            } else {
                categories.append(trimmed)
            }
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
    
    // MARK: - Smart Categorization with Reasoning
    
    /// Categorizes a joke and returns detailed reasoning
    static func categorizeJoke(_ joke: Joke, using categories: [String]) -> CategorizationResult {
        let text = (joke.title + " " + joke.content).lowercased()
        
        var categoryScores: [(category: String, score: Int, matches: [String])] = []
        
        for category in categories {
            guard category != "Other" else { continue }
            
            let keywords = categoryKeywords[category] ?? []
            var score = 0
            var matchedKeywords: [String] = []
            
            for keyword in keywords {
                if smartContains(text: text, keyword: keyword) {
                    score += 1
                    matchedKeywords.append(keyword)
                    
                    // Bonus points for longer/more specific keywords
                    if keyword.contains(" ") {
                        score += 1  // Phrases get bonus
                    }
                }
            }
            
            if score > 0 {
                categoryScores.append((category, score, matchedKeywords))
            }
        }
        
        // Sort by score (highest first)
        categoryScores.sort { $0.score > $1.score }
        
        // Build result with reasoning
        if let best = categoryScores.first, best.score >= 1 {
            let confidence = generateConfidence(score: best.score)
            let reasoning = generateReasoning(
                category: best.category,
                matchCount: best.matches.count,
                keywords: best.matches
            )
            
            return CategorizationResult(
                category: best.category,
                confidence: confidence,
                matchedKeywords: best.matches,
                reasoning: reasoning
            )
        }
        
        // Default to "Other"
        let defaultCategory = categories.contains("Other") ? "Other" : (categories.first ?? "Other")
        return CategorizationResult(
            category: defaultCategory,
            confidence: "Low",
            matchedKeywords: [],
            reasoning: "No specific keywords matched - categorized as general content"
        )
    }
    
    /// Finds the best category using smart keyword matching (legacy method)
    static func findBestCategory(for joke: Joke, using categories: [String]) -> String {
        return categorizeJoke(joke, using: categories).category
    }
    
    /// Generates confidence level based on match score
    private static func generateConfidence(score: Int) -> String {
        switch score {
        case 6...: return "Very High"
        case 4...5: return "High"
        case 2...3: return "Medium"
        case 1: return "Low"
        default: return "None"
        }
    }
    
    /// Generates human-readable reasoning
    private static func generateReasoning(category: String, matchCount: Int, keywords: [String]) -> String {
        let keywordList = keywords.prefix(5).joined(separator: ", ")
        let moreText = keywords.count > 5 ? " and \(keywords.count - 5) more" : ""
        
        let confidenceText: String
        switch matchCount {
        case 6...: confidenceText = "Very confident"
        case 4...5: confidenceText = "Confident"
        case 2...3: confidenceText = "Moderately confident"
        default: confidenceText = "Possibly"
        }
        
        return "\(confidenceText) this is about \(category.lowercased()) — found: \(keywordList)\(moreText)"
    }
    
    /// Smart text matching - handles word boundaries better
    private static func smartContains(text: String, keyword: String) -> Bool {
        // For phrases (multi-word keywords), use simple contains
        if keyword.contains(" ") {
            return text.contains(keyword)
        }
        
        // For single words, try to match word boundaries
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: keyword))\\b"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(text.startIndex..., in: text)
            return regex.firstMatch(in: text, options: [], range: range) != nil
        }
        
        // Fallback to simple contains
        return text.contains(keyword)
    }
    
    // MARK: - Organize All Jokes
    
    static func organizeAllJokes(
        jokes: [Joke],
        categories: [String],
        folders: [JokeFolder],
        modelContext: ModelContext
    ) -> (count: Int, results: [CategorizationResult]) {
        var organizedCount = 0
        var folderMap: [String: JokeFolder] = [:]
        var results: [CategorizationResult] = []
        
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
            let result = categorizeJoke(joke, using: categories)
            results.append(result)
            
            if let folder = folderMap[result.category] {
                joke.folder = folder
                organizedCount += 1
            }
        }
        
        try? modelContext.save()
        return (organizedCount, results)
    }
}
