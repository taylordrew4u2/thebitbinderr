//
//  AutoOrganizeService.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/7/25.
//

import Foundation
import SwiftData

class AutoOrganizeService {
    
    // MARK: - Configuration
    
    private static let confidenceThresholdForAutoOrganize: Double = 0.5
    private static let confidenceThresholdForSuggestion: Double = 0.3
    private static let multiCategoryThreshold: Double = 0.4
    
    // MARK: - Smart Auto-Organize Categories with Weighted Keywords
    
    private static let categories: [String: CategoryKeywords] = [
        "Technology & Programming": CategoryKeywords(
            keywords: [
                ("programmer", 1.0), ("developer", 1.0), ("coding", 1.0), ("software", 0.9),
                ("hardware", 0.8), ("computer", 0.8), ("code", 1.0), ("bug", 0.9),
                ("debug", 0.9), ("database", 0.8), ("server", 0.7), ("network", 0.7),
                ("internet", 0.6), ("wifi", 0.5), ("bluetooth", 0.5), ("app", 0.8),
                ("algorithm", 1.0), ("function", 0.7), ("variable", 0.8), ("java", 1.0),
                ("python", 1.0), ("swift", 1.0), ("javascript", 1.0), ("html", 0.9),
                ("css", 0.9), ("sql", 0.9), ("api", 0.9), ("json", 0.8),
                ("tech", 0.7), ("gadget", 0.6), ("robot", 0.8), ("ai", 1.0),
                ("machine learning", 1.0), ("bitcoin", 0.7), ("crypto", 0.7),
                ("data science", 0.9), ("cloud", 0.7)
            ],
            weight: 1.0
        ),
        "Relationships & Dating": CategoryKeywords(
            keywords: [
                ("boyfriend", 1.0), ("girlfriend", 1.0), ("husband", 0.9), ("wife", 0.9),
                ("marriage", 0.9), ("wedding", 0.8), ("divorce", 0.9), ("date", 0.7),
                ("dating", 1.0), ("love", 0.9), ("romance", 0.9), ("kiss", 0.8),
                ("relationship", 1.0), ("partner", 0.8), ("spouse", 0.8), ("breakup", 0.9),
                ("cheating", 0.9), ("flirt", 0.8), ("crush", 0.8), ("romantic", 0.8),
                ("dating app", 0.9), ("single", 0.6), ("lonely", 0.6)
            ],
            weight: 1.0
        ),
        "Work & Office": CategoryKeywords(
            keywords: [
                ("boss", 1.0), ("employee", 0.9), ("manager", 0.9), ("office", 0.9),
                ("work", 0.8), ("job", 0.9), ("interview", 0.8), ("resume", 0.8),
                ("meeting", 0.7), ("deadline", 0.7), ("project", 0.7), ("coworker", 0.9),
                ("colleague", 0.8), ("fired", 0.9), ("quit", 0.8), ("promotion", 0.8),
                ("salary", 0.8), ("paycheck", 0.8), ("company", 0.7), ("business", 0.6),
                ("workplace", 0.8), ("cubicle", 0.8)
            ],
            weight: 1.0
        ),
        "Animals": CategoryKeywords(
            keywords: [
                ("dog", 1.0), ("cat", 1.0), ("bird", 0.9), ("fish", 0.8), ("snake", 0.9),
                ("bear", 0.9), ("lion", 0.9), ("tiger", 0.9), ("elephant", 0.8),
                ("monkey", 0.8), ("horse", 0.8), ("cow", 0.8), ("chicken", 0.8),
                ("pig", 0.8), ("duck", 0.8), ("penguin", 0.8), ("wolf", 0.8),
                ("fox", 0.8), ("deer", 0.8), ("rabbit", 0.8), ("mouse", 0.8),
                ("rat", 0.8), ("squirrel", 0.8), ("animal", 0.6), ("pet", 0.7),
                ("creature", 0.6), ("paws", 0.7)
            ],
            weight: 0.95
        ),
        "Food & Cooking": CategoryKeywords(
            keywords: [
                ("food", 0.8), ("eat", 0.8), ("eating", 0.8), ("dinner", 0.9),
                ("lunch", 0.9), ("breakfast", 0.9), ("cook", 0.9), ("cooking", 0.9),
                ("recipe", 0.8), ("restaurant", 0.8), ("pizza", 1.0), ("burger", 1.0),
                ("steak", 0.9), ("chicken", 0.6), ("fish", 0.6), ("vegetable", 0.7),
                ("fruit", 0.7), ("dessert", 0.9), ("cake", 0.9), ("bread", 0.8),
                ("pasta", 0.9), ("rice", 0.7), ("soup", 0.8), ("salad", 0.8),
                ("drink", 0.6), ("beer", 0.8), ("wine", 0.8), ("coffee", 0.8),
                ("tea", 0.7), ("chocolate", 0.8), ("candy", 0.8), ("nutrition", 0.6),
                ("chef", 0.8), ("kitchen", 0.7), ("meal", 0.8)
            ],
            weight: 0.95
        ),
        "Travel & Places": CategoryKeywords(
            keywords: [
                ("travel", 1.0), ("trip", 0.9), ("vacation", 0.9), ("plane", 0.8),
                ("airport", 0.8), ("hotel", 0.8), ("beach", 0.8), ("mountain", 0.8),
                ("country", 0.6), ("city", 0.6), ("paris", 0.9), ("london", 0.9),
                ("new york", 0.9), ("tourist", 0.8), ("passport", 0.8), ("flight", 0.8),
                ("adventure", 0.7), ("explore", 0.7), ("visiting", 0.7), ("visited", 0.7),
                ("road trip", 0.9), ("highway", 0.7), ("destination", 0.7), ("tour", 0.8)
            ],
            weight: 0.95
        ),
        "School & Education": CategoryKeywords(
            keywords: [
                ("school", 1.0), ("college", 0.9), ("university", 0.9), ("student", 0.9),
                ("teacher", 0.9), ("professor", 0.9), ("class", 0.8), ("test", 0.8),
                ("exam", 0.9), ("homework", 0.9), ("grade", 0.9), ("degree", 0.8),
                ("education", 0.8), ("study", 0.7), ("learning", 0.7), ("high school", 1.0),
                ("middle school", 1.0), ("elementary", 0.9), ("principal", 0.8), ("tuition", 0.8),
                ("textbook", 0.8), ("campus", 0.8)
            ],
            weight: 0.95
        ),
        "Sports": CategoryKeywords(
            keywords: [
                ("sport", 0.8), ("game", 0.7), ("football", 1.0), ("basketball", 1.0),
                ("soccer", 1.0), ("baseball", 1.0), ("hockey", 1.0), ("tennis", 0.9),
                ("golf", 0.9), ("running", 0.7), ("swimming", 0.7), ("boxing", 0.9),
                ("wrestling", 0.8), ("yoga", 0.7), ("gym", 0.7), ("workout", 0.7),
                ("exercise", 0.6), ("coach", 0.8), ("team", 0.6), ("player", 0.7),
                ("match", 0.6), ("score", 0.5), ("win", 0.5), ("lose", 0.5),
                ("race", 0.7), ("athlete", 0.8), ("championship", 0.8)
            ],
            weight: 0.95
        ),
        "Family & Kids": CategoryKeywords(
            keywords: [
                ("mom", 1.0), ("dad", 1.0), ("mother", 0.9), ("father", 0.9),
                ("brother", 0.9), ("sister", 0.9), ("son", 0.9), ("daughter", 0.9),
                ("kid", 0.9), ("kids", 0.9), ("child", 0.8), ("children", 0.8),
                ("family", 0.8), ("parent", 0.8), ("grandma", 0.9), ("grandpa", 0.9),
                ("uncle", 0.8), ("aunt", 0.8), ("cousin", 0.8), ("baby", 0.8),
                ("toddler", 0.8), ("teenager", 0.8), ("sibling", 0.8)
            ],
            weight: 0.95
        ),
        "Health & Medicine": CategoryKeywords(
            keywords: [
                ("doctor", 1.0), ("hospital", 0.9), ("medicine", 0.9), ("sick", 0.9),
                ("illness", 0.9), ("disease", 0.9), ("health", 0.8), ("virus", 0.8),
                ("vaccine", 0.8), ("nurse", 0.9), ("surgery", 0.8), ("pain", 0.7),
                ("injury", 0.8), ("broken", 0.7), ("fracture", 0.8), ("cancer", 0.8),
                ("mental health", 0.9), ("therapy", 0.8), ("therapist", 0.8), ("anxiety", 0.8),
                ("depression", 0.8), ("diet", 0.6), ("fitness", 0.6), ("clinic", 0.8)
            ],
            weight: 0.95
        ),
        "Money & Finance": CategoryKeywords(
            keywords: [
                ("money", 1.0), ("cash", 0.9), ("dollar", 0.8), ("payment", 0.8),
                ("bill", 0.7), ("expensive", 0.7), ("cheap", 0.7), ("price", 0.7),
                ("cost", 0.7), ("rich", 0.8), ("poor", 0.8), ("broke", 0.8),
                ("bank", 0.8), ("account", 0.7), ("credit", 0.7), ("debt", 0.8),
                ("loan", 0.8), ("investment", 0.8), ("stock", 0.8), ("income", 0.8),
                ("spend", 0.6), ("save", 0.6), ("budget", 0.8), ("tax", 0.8),
                ("salary", 0.8), ("financial", 0.7)
            ],
            weight: 0.95
        ),
        "Dark Humor": CategoryKeywords(
            keywords: [
                ("death", 0.9), ("kill", 0.9), ("murder", 0.9), ("die", 0.8),
                ("dead", 0.8), ("suicide", 1.0), ("funeral", 0.8), ("ghost", 0.7),
                ("zombie", 0.8), ("dark", 0.6), ("evil", 0.7), ("hell", 0.7),
                ("devil", 0.7), ("curse", 0.7), ("haunted", 0.7), ("scary", 0.6),
                ("horror", 0.8), ("blood", 0.8), ("suffering", 0.8), ("torture", 0.8),
                ("violence", 0.8), ("crime", 0.7), ("criminal", 0.7)
            ],
            weight: 0.95
        )
    ]
    
    // MARK: - Main Categorization Method
    
    /// Intelligently categorizes a joke with confidence scoring
    static func categorizeJoke(_ joke: Joke) -> [CategoryMatch] {
        let content = (joke.title + " " + joke.content).lowercased()
        var matches: [CategoryMatch] = []
        
        for (categoryName, keywords) in categories {
            let confidence = calculateConfidence(
                for: content,
                with: keywords,
                jokeLength: joke.content.count
            )
            
            if confidence >= confidenceThresholdForSuggestion {
                let matchedKeywords = keywords.keywords
                    .filter { content.containsWord($0.0) }
                    .map { $0.0 }
                
                let reasoning = generateReasoning(
                    category: categoryName,
                    matchCount: matchedKeywords.count,
                    confidence: confidence
                )
                
                matches.append(CategoryMatch(
                    category: categoryName,
                    confidence: confidence,
                    reasoning: reasoning,
                    matchedKeywords: matchedKeywords,
                    styleTags: [],
                    emotionalTone: nil,
                    craftSignals: [],
                    structureScore: nil
                ))
            }
        }
        
        // Sort by confidence, highest first
        matches.sort { $0.confidence > $1.confidence }
        
        // Store in joke for reference
        joke.categorizationResults = matches
        if let topMatch = matches.first {
            joke.primaryCategory = topMatch.category
            joke.allCategories = matches
                .filter { $0.confidence >= multiCategoryThreshold }
                .map { $0.category }
            
            for match in matches {
                joke.categoryConfidenceScores[match.category] = match.confidence
            }
        }
        
        return matches
    }
    
    /// Simple auto-categorize method for text content (used by TextRecognitionService)
    static func autoCategorize(title: String, content: String) -> String? {
        let text = (title + " " + content).lowercased()
        
        var bestCategory: String?
        var bestScore: Double = 0
        
        for (categoryName, keywordSet) in categories {
            var score: Double = 0
            var matchCount = 0
            
            for (keyword, weight) in keywordSet.keywords {
                if text.containsWord(keyword) {
                    score += weight
                    matchCount += 1
                }
            }
            
            if matchCount > 0 {
                let normalizedScore = score / Double(keywordSet.keywords.count) * keywordSet.weight
                if normalizedScore > bestScore && normalizedScore >= confidenceThresholdForSuggestion {
                    bestScore = normalizedScore
                    bestCategory = categoryName
                }
            }
        }
        
        return bestCategory
    }
    
    /// Gets the best category for auto-organizing
    static func getBestCategory(_ joke: Joke) -> String? {
        let matches = categorizeJoke(joke)
        
        // Return first match if confidence is high enough for auto-organize
        if let topMatch = matches.first, topMatch.confidence >= confidenceThresholdForAutoOrganize {
            return topMatch.category
        }
        
        return nil
    }
    
    /// Auto-organizes jokes with smart categorization
    static func autoOrganizeJokes(
        unorganizedJokes: [Joke],
        existingFolders: [JokeFolder],
        modelContext: ModelContext,
        completion: @escaping (Int, Int) -> Void
    ) {
        var organizedCount = 0
        var suggestedCount = 0
        var folderMap: [String: JokeFolder] = [:]
        
        // Create a map of existing folders
        for folder in existingFolders {
            folderMap[folder.name] = folder
        }
        
        for joke in unorganizedJokes {
            if let categoryName = getBestCategory(joke) {
                // Get or create folder
                var targetFolder = folderMap[categoryName]
                if targetFolder == nil {
                    targetFolder = JokeFolder(name: categoryName)
                    modelContext.insert(targetFolder!)
                    folderMap[categoryName] = targetFolder
                    print("✅ AUTO-ORGANIZE: Created folder '\(categoryName)'")
                }
                
                // Assign joke to folder
                joke.folder = targetFolder
                organizedCount += 1
                
                if let confidence = joke.categoryConfidenceScores[categoryName] {
                    print("✅ AUTO-ORGANIZE: Moved '\(joke.title)' to '\(categoryName)' (\(String(format: "%.0f%%", confidence * 100)))")
                }
            } else {
                // Low confidence - suggest categories instead
                let matches = joke.categorizationResults
                if !matches.isEmpty {
                    print("⚠️  AUTO-ORGANIZE: Suggestion for '\(joke.title)': \(matches.first?.category ?? "General")")
                    suggestedCount += 1
                }
            }
        }
        
        // Ensure "Recently Added" folder exists
        _ = ensureRecentlyAddedFolder(existingFolders: existingFolders, modelContext: modelContext)
        
        completion(organizedCount, suggestedCount)
    }
    
    /// Ensures the "Recently Added" folder always exists
    @discardableResult
    static func ensureRecentlyAddedFolder(
        existingFolders: [JokeFolder],
        modelContext: ModelContext
    ) -> JokeFolder {
        if let recentFolder = existingFolders.first(where: { $0.name == "Recently Added" }) {
            return recentFolder
        }
        
        let recentFolder = JokeFolder(name: "Recently Added")
        modelContext.insert(recentFolder)
        print("✅ AUTO-ORGANIZE: Created 'Recently Added' folder")
        return recentFolder
    }
    
    // MARK: - Helper Methods for Smart Categorization
    
    /// Calculates confidence score for a category match
    private static func calculateConfidence(
        for content: String,
        with keywordSet: CategoryKeywords,
        jokeLength: Int
    ) -> Double {
        var totalScore: Double = 0
        var matchCount = 0
        
        for (keyword, weight) in keywordSet.keywords {
            if content.containsWord(keyword) {
                totalScore += weight
                matchCount += 1
            }
        }
        
        if matchCount == 0 {
            return 0
        }
        
        // Normalize score and apply additional factors
        var confidence = min(totalScore / Double(keywordSet.keywords.count), 1.0)
        
        // Boost confidence if multiple keywords match
        if matchCount > 1 {
            confidence *= (1.0 + Double(matchCount - 1) * 0.1)
        }
        
        // Apply length bonus for longer jokes (more reliable categorization)
        let lengthBonus = min(Double(jokeLength) / 500.0, 0.2)
        confidence *= (1.0 + lengthBonus)
        
        // Apply category weight
        confidence *= keywordSet.weight
        
        return min(confidence, 1.0)
    }
    
    /// Generates human-readable reasoning for categorization
    private static func generateReasoning(
        category: String,
        matchCount: Int,
        confidence: Double
    ) -> String {
        let confidenceLevel: String
        switch confidence {
        case 0.8...:
            confidenceLevel = "very confident"
        case 0.6..<0.8:
            confidenceLevel = "confident"
        case 0.4..<0.6:
            confidenceLevel = "moderately confident"
        default:
            confidenceLevel = "suggested"
        }
        
        let keywordText = matchCount == 1 ? "keyword" : "keywords"
        return "Found \(matchCount) \(keywordText) - \(confidenceLevel) this is about \(category.lowercased())"
    }
    
    // MARK: - Gets all available categories
    
    static func getCategories() -> [String] {
        return Array(categories.keys).sorted()
    }
}

// MARK: - Supporting Types

struct CategoryKeywords {
    let keywords: [(String, Double)]  // keyword, weight
    let weight: Double
}

// MARK: - String Extensions for Smart Matching

extension String {
    /// Checks if string contains a word with boundaries
    /// (not just substring matching)
    func containsWord(_ word: String) -> Bool {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let range = NSRange(self.startIndex..., in: self)
            return regex.firstMatch(in: self, options: [], range: range) != nil
        } catch {
            // Fallback to simple contains
            return self.contains(word)
        }
    }
}
