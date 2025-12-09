//
//  AutoOrganizeService.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/7/25.
//

import Foundation
import SwiftData

class AutoOrganizeService {
    
    private static let confidenceThresholdForAutoOrganize: Double = 0.5
    private static let confidenceThresholdForSuggestion: Double = 0.3
    private static let multiCategoryThreshold: Double = 0.4
    
    // Comedy Style Categories with Signature Keywords
    private static let categories: [String: CategoryKeywords] = [
        "Puns": CategoryKeywords(keywords: [("wordplay", 1.0), ("pun", 1.0), ("play on words", 1.0), ("double meaning", 0.9), ("homophone", 1.0), ("word", 0.7), ("like", 0.6), ("flies", 0.7), ("fruit", 0.7), ("arrow", 0.6), ("time", 0.5), ("banana", 0.6)], weight: 1.0),
        "Roasts": CategoryKeywords(keywords: [("roast", 1.0), ("insult", 0.9), ("making fun", 0.9), ("you're so", 0.8), ("ugly", 0.8), ("stupid", 0.8), ("dumb", 0.8), ("idiot", 0.8), ("laugh", 0.6), ("burn", 0.7), ("own", 0.7), ("destroy", 0.6)], weight: 1.0),
        "One-Liners": CategoryKeywords(keywords: [("one liner", 1.0), ("quick", 0.7), ("short", 0.6), ("wife", 0.5), ("told", 0.5), ("eyebrows", 0.7), ("surprised", 0.6), ("simple joke", 0.8)], weight: 1.0),
        "Knock-Knock": CategoryKeywords(keywords: [("knock knock", 1.0), ("who's there", 1.0), ("who is there", 1.0), ("boo", 0.8), ("interrupting", 0.9), ("knock", 0.7)], weight: 1.0),
        "Dad Jokes": CategoryKeywords(keywords: [("dad joke", 1.0), ("dad", 0.7), ("terrible", 0.6), ("corny", 0.8), ("stupid", 0.6), ("field", 0.7), ("scarecrow", 0.7), ("outstanding", 0.6), ("award", 0.5)], weight: 1.0),
        "Sarcasm": CategoryKeywords(keywords: [("sarcasm", 1.0), ("sarcastic", 1.0), ("right", 0.6), ("sure", 0.6), ("great", 0.5), ("wonderful", 0.5), ("fantastic", 0.5), ("oh great", 0.8), ("just what i wanted", 0.8), ("obviously", 0.6), ("yeah right", 0.8)], weight: 1.0),
        "Irony": CategoryKeywords(keywords: [("irony", 1.0), ("ironic", 1.0), ("weird", 0.7), ("unexpected", 0.7), ("opposite", 0.7), ("fire station", 0.9), ("burned down", 0.8), ("paradox", 0.8)], weight: 1.0),
        "Satire": CategoryKeywords(keywords: [("satire", 1.0), ("satirical", 1.0), ("making fun of society", 1.0), ("mock", 0.8), ("social commentary", 0.9), ("government", 0.6), ("politics", 0.7), ("system", 0.6), ("daily show", 0.8)], weight: 1.0),
        "Dark Humor": CategoryKeywords(keywords: [("death", 0.9), ("kill", 0.9), ("murder", 0.9), ("die", 0.8), ("dead", 0.8), ("suicide", 1.0), ("funeral", 0.8), ("dark", 0.8), ("tragedy", 0.9), ("blast", 0.7), ("bomber", 0.8), ("disturbing", 0.8)], weight: 1.0),
        "Observational": CategoryKeywords(keywords: [("why do we", 1.0), ("why does", 0.9), ("have you ever", 0.8), ("observe", 0.8), ("notice", 0.8), ("everyday", 0.7), ("driveway", 0.8), ("parkway", 0.8), ("parking", 0.7), ("drive", 0.6)], weight: 1.0),
        "Anecdotal": CategoryKeywords(keywords: [("one time", 1.0), ("so there i was", 1.0), ("story", 0.8), ("true story", 0.9), ("happened to me", 0.9), ("my friend", 0.7), ("drunk", 0.7), ("peed", 0.8), ("long story", 0.7), ("reminds me of", 0.6)], weight: 1.0),
        "Self-Deprecating": CategoryKeywords(keywords: [("i'm not", 1.0), ("i'm so", 0.9), ("myself", 0.7), ("making fun of myself", 0.9), ("bad at", 0.8), ("terrible", 0.7), ("not good at", 0.8), ("loser", 0.7), ("stupid", 0.6), ("ugly", 0.6)], weight: 1.0),
        "Anti-Jokes": CategoryKeywords(keywords: [("anti joke", 1.0), ("not funny", 0.8), ("wasn't really a joke", 0.9), ("chicken cross the road", 0.9), ("other side", 0.8), ("obvious", 0.7), ("subvert expectations", 0.8)], weight: 1.0),
        "Riddles": CategoryKeywords(keywords: [("riddle", 1.0), ("what has", 1.0), ("clever answer", 0.9), ("four legs", 0.8), ("morning", 0.6), ("afternoon", 0.6), ("evening", 0.6), ("man", 0.5), ("sphinx", 0.8), ("puzzle", 0.8)], weight: 1.0)
    ]
    
    static func categorizeJoke(_ joke: Joke) -> [CategoryMatch] {
        let content = (joke.title + " " + joke.content).lowercased()
        var matches: [CategoryMatch] = []
        
        for (categoryName, keywords) in categories {
            let confidence = calculateConfidence(for: content, with: keywords, jokeLength: joke.content.count)
            if confidence >= confidenceThresholdForSuggestion {
                let matchedKeywords = keywords.keywords.filter { content.containsWord($0.0) }.map { $0.0 }
                let reasoning = generateReasoning(category: categoryName, matchCount: matchedKeywords.count, confidence: confidence)
                
                matches.append(CategoryMatch(category: categoryName, confidence: confidence, reasoning: reasoning, matchedKeywords: matchedKeywords, styleTags: [], emotionalTone: nil, craftSignals: [], structureScore: nil))
            }
        }
        
        matches.sort { $0.confidence > $1.confidence }
        joke.categorizationResults = matches
        if let topMatch = matches.first {
            joke.primaryCategory = topMatch.category
            joke.allCategories = matches.filter { $0.confidence >= multiCategoryThreshold }.map { $0.category }
            for match in matches {
                joke.categoryConfidenceScores[match.category] = match.confidence
            }
        }
        
        return matches
    }
    
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
    
    static func getBestCategory(_ joke: Joke) -> String? {
        let matches = categorizeJoke(joke)
        if let topMatch = matches.first, topMatch.confidence >= confidenceThresholdForAutoOrganize {
            return topMatch.category
        }
        return nil
    }
    
    static func autoOrganizeJokes(unorganizedJokes: [Joke], existingFolders: [JokeFolder], modelContext: ModelContext, completion: @escaping (Int, Int) -> Void) {
        var organizedCount = 0
        var suggestedCount = 0
        var folderMap: [String: JokeFolder] = [:]
        
        for folder in existingFolders {
            folderMap[folder.name] = folder
        }
        
        for joke in unorganizedJokes {
            if let categoryName = getBestCategory(joke) {
                var targetFolder = folderMap[categoryName]
                if targetFolder == nil {
                    targetFolder = JokeFolder(name: categoryName)
                    modelContext.insert(targetFolder!)
                    folderMap[categoryName] = targetFolder
                    print("✅ Created: \(categoryName)")
                }
                joke.folder = targetFolder
                organizedCount += 1
                print("✅ Organized '\(joke.title)' → '\(categoryName)'")
            } else {
                let matches = joke.categorizationResults
                if !matches.isEmpty {
                    print("⚠️ Suggested '\(joke.title)' → '\(matches.first?.category ?? "Unknown")'")
                    suggestedCount += 1
                }
            }
        }
        
        _ = ensureRecentlyAddedFolder(existingFolders: existingFolders, modelContext: modelContext)
        
        do {
            try modelContext.save()
            print("✅ Saved \(organizedCount) jokes")
        } catch {
            print("❌ Save error: \(error)")
        }
        
        completion(organizedCount, suggestedCount)
    }
    
    @discardableResult
    static func ensureRecentlyAddedFolder(existingFolders: [JokeFolder], modelContext: ModelContext) -> JokeFolder {
        if let recentFolder = existingFolders.first(where: { $0.name == "Recently Added" }) {
            return recentFolder
        }
        let recentFolder = JokeFolder(name: "Recently Added")
        modelContext.insert(recentFolder)
        return recentFolder
    }
    
    static func getCategories() -> [String] {
        return Array(categories.keys).sorted()
    }
    
    static func assignJokeToFolder(_ joke: Joke, folderName: String, modelContext: ModelContext) {
        do {
            let folders = try modelContext.fetch(FetchDescriptor<JokeFolder>())
            var targetFolder = folders.first(where: { $0.name == folderName })
            if targetFolder == nil {
                targetFolder = JokeFolder(name: folderName)
                modelContext.insert(targetFolder!)
            }
            joke.folder = targetFolder
            try modelContext.save()
            print("✅ Assigned '\(joke.title)' → '\(folderName)'")
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    private static func calculateConfidence(for content: String, with keywordSet: CategoryKeywords, jokeLength: Int) -> Double {
        var totalScore: Double = 0
        var matchCount = 0
        for (keyword, weight) in keywordSet.keywords {
            if content.containsWord(keyword) {
                totalScore += weight
                matchCount += 1
            }
        }
        if matchCount == 0 { return 0 }
        var confidence = min(totalScore / Double(keywordSet.keywords.count), 1.0)
        if matchCount > 1 { confidence *= (1.0 + Double(matchCount - 1) * 0.1) }
        let lengthBonus = min(Double(jokeLength) / 500.0, 0.2)
        confidence *= (1.0 + lengthBonus)
        confidence *= keywordSet.weight
        return min(confidence, 1.0)
    }
    
    private static func generateReasoning(category: String, matchCount: Int, confidence: Double) -> String {
        let level = confidence >= 0.8 ? "very confident" : confidence >= 0.6 ? "confident" : confidence >= 0.4 ? "moderately confident" : "suggested"
        let text = matchCount == 1 ? "keyword" : "keywords"
        return "Found \(matchCount) \(text) - \(level)"
    }
}

struct CategoryKeywords {
    let keywords: [(String, Double)]
    let weight: Double
    init(keywords: [(String, Double)], weight: Double = 1.0) {
        self.keywords = keywords
        self.weight = weight
    }
}

extension String {
    func containsWord(_ word: String) -> Bool {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let range = NSRange(self.startIndex..., in: self)
            return regex.firstMatch(in: self, options: [], range: range) != nil
        } catch {
            return self.contains(word)
        }
    }
}
