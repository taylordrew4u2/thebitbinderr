//
//  AutoOrganizeService.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/7/25.
//

import Foundation
import SwiftData

struct StyleAnalysis {
    let tags: [String]
    let tone: String?
    let craftSignals: [String]
    let structureScore: Double
    let hook: String?
}

struct TopicMatch {
    let category: String
    let confidence: Double
    let evidence: [String]
}

class AutoOrganizeService {
    // MARK: - Configuration
    private static let confidenceThresholdForAutoOrganize: Double = 0.55
    private static let confidenceThresholdForSuggestion: Double = 0.25
    private static let multiCategoryThreshold: Double = 0.35
    
    // MARK: - Comedy Category Lexicon
    private static let categories: [String: CategoryKeywords] = [
        "Puns": CategoryKeywords(keywords: [("pun", 1.0), ("wordplay", 1.0), ("play on words", 1.0), ("double meaning", 0.9), ("homophone", 0.9), ("fruit flies", 0.8), ("arrow", 0.6)]),
        "Roasts": CategoryKeywords(keywords: [("roast", 1.0), ("insult", 0.9), ("you're so", 0.9), ("ugly", 0.9), ("trash", 0.8), ("burn", 0.7)]),
        "One-Liners": CategoryKeywords(keywords: [("one liner", 1.0), ("quick", 0.7), ("short", 0.7), ("punchline", 0.8), ("she looked", 0.7)]),
        "Knock-Knock": CategoryKeywords(keywords: [("knock knock", 1.0), ("who's there", 1.0), ("boo who", 0.9), ("interrupting", 0.8)]),
        "Dad Jokes": CategoryKeywords(keywords: [("dad joke", 1.0), ("scarecrow", 0.9), ("outstanding in his field", 1.0), ("corny", 0.8), ("groan", 0.6)]),
        "Sarcasm": CategoryKeywords(keywords: [("sarcasm", 1.0), ("sarcastic", 1.0), ("oh great", 1.0), ("yeah right", 0.9), ("sure", 0.7)]),
        "Irony": CategoryKeywords(keywords: [("irony", 1.0), ("ironic", 1.0), ("unexpected", 0.8), ("fire station", 0.9), ("burned down", 0.9)]),
        "Satire": CategoryKeywords(keywords: [("satire", 1.0), ("satirical", 1.0), ("society", 0.8), ("politics", 0.8), ("the daily show", 1.0)]),
        "Dark Humor": CategoryKeywords(keywords: [("dark humor", 1.0), ("death", 0.9), ("tragedy", 0.9), ("suicide", 1.0), ("bomber", 0.8), ("blast", 0.7)]),
        "Observational": CategoryKeywords(keywords: [("observational", 1.0), ("why do", 0.9), ("have you ever", 0.9), ("driveway", 0.8), ("parkway", 0.8)]),
        "Anecdotal": CategoryKeywords(keywords: [("one time", 1.0), ("story", 0.8), ("this happened", 0.9), ("friend", 0.7), ("drunk", 0.6)]),
        "Self-Deprecating": CategoryKeywords(keywords: [("self deprecating", 1.0), ("i'm so", 0.9), ("i'm not", 0.9), ("i suck", 0.8), ("i'm terrible", 0.8)]),
        "Anti-Jokes": CategoryKeywords(keywords: [("anti joke", 1.0), ("not really a joke", 0.9), ("why did the chicken", 0.9), ("other side", 0.8)]),
        "Riddles": CategoryKeywords(keywords: [("riddle", 1.0), ("what has", 1.0), ("clever answer", 0.9), ("legs", 0.7), ("morning", 0.6), ("evening", 0.6)]),
        "Other": CategoryKeywords(keywords: [], weight: 0.2)
    ]
    
    // MARK: - Style Lexicons
    private static let styleCueLexicon: [String: [String]] = [
        "Self-Deprecating": ["i'm so", "i'm not", "i suck", "i'm terrible"],
        "Observational": ["have you ever", "why do", "isn't it weird"],
        "Anecdotal": ["one time", "story", "so there i was"],
        "Sarcasm": ["yeah right", "sure", "great", "wonderful", "of course"],
        "Dark": ["death", "suicide", "funeral", "grave"],
        "Satire": ["society", "politics", "system", "corporate"],
        "Roast": ["you're so", "look at you", "sit down"],
        "Dad": ["dad", "kids", "son", "daughter"],
        "Wordplay": ["pun", "wordplay", "double meaning"],
        "Anti-Joke": ["not even a joke", "literal", "just"],
        "Knock-Knock": ["knock knock", "who's there"],
        "Riddle": ["what has", "who am i", "clever answer"],
        "Irony": ["ironically", "turns out", "of course the"],
        "One-Liner": ["short", "quick", "line"],
        "Story": ["long story", "cut to", "flash forward"],
        "Roast": ["look at you", "you're so"],
        "Blue": ["explicit", "naughty", "bedroom"],
        "Topical": ["today", "headline", "trending"],
        "Crowd": ["sir", "ma'am", "front row"]
    ]
    
    private static let toneKeywords: [String: [String]] = [
        "Playful": ["lol", "haha", "silly", "goofy"],
        "Cynical": ["of course", "naturally", "figures"],
        "Angry": ["hate", "furious", "annoyed"],
        "Confessional": ["honestly", "truth", "real talk"],
        "Dark": ["death", "suicide", "grave"],
        "Hopeful": ["maybe", "believe", "hope"],
        "Cringe": ["awkward", "embarrassing"]
    ]
    
    private static let craftSignalsLexicon: [String: [String]] = [
        "Rule of Three": ["first", "second", "third", "one", "two", "three"],
        "Callback": ["again", "like before", "remember"],
        "Misdirection": ["but", "instead", "actually", "turns out"],
        "Act-Out": ["(acts", "[act", "stage"],
        "Crowd Work": ["sir", "ma'am", "front row", "table"],
        "Question/Punch": ["?", "answer is", "because"],
        "Absurd Heighten": ["then suddenly", "escalated", "spiraled"]
    ]
    
    // MARK: - Public API
    static func categorizeJoke(_ joke: Joke) -> [CategoryMatch] {
        let normalized = normalize(joke.title + " " + joke.content)
        let style = analyzeStyle(in: normalized)
        let topicMatches = scoreCategories(in: normalized)
        var matches: [CategoryMatch] = []
        
        for match in topicMatches where match.confidence >= confidenceThresholdForSuggestion {
            matches.append(
                CategoryMatch(
                    category: match.category,
                    confidence: match.confidence,
                    reasoning: reasoning(for: match, style: style),
                    matchedKeywords: match.evidence,
                    styleTags: style.tags,
                    emotionalTone: style.tone,
                    craftSignals: style.craftSignals,
                    structureScore: style.structureScore
                )
            )
        }
        
        if matches.isEmpty {
            matches.append(CategoryMatch(
                category: "Other",
                confidence: 0.2,
                reasoning: "No clear comedic cues detected — filing under Other for review.",
                matchedKeywords: [],
                styleTags: style.tags,
                emotionalTone: style.tone,
                craftSignals: style.craftSignals,
                structureScore: style.structureScore
            ))
        }
        
        matches.sort { $0.confidence > $1.confidence }
        hydrate(joke, with: matches)
        return matches
    }
    
    static func autoOrganizeJokes(
        unorganizedJokes: [Joke],
        existingFolders: [JokeFolder],
        modelContext: ModelContext,
        completion: @escaping (Int, Int) -> Void
    ) {
        var organized = 0
        var suggested = 0
        var folderMap = Dictionary(uniqueKeysWithValues: existingFolders.map { ($0.name, $0) })
        
        for joke in unorganizedJokes {
            let matches = categorizeJoke(joke)
            let top = matches.first
            var category = top?.category ?? "Other"
            
            if let best = top, best.confidence >= confidenceThresholdForAutoOrganize {
                // solid match
            } else {
                suggested += 1
                if top == nil || top?.confidence ?? 0 < 0.15 {
                    category = "Other"
                }
            }
            
            if folderMap[category] == nil {
                let folder = JokeFolder(name: category)
                modelContext.insert(folder)
                folderMap[category] = folder
                print("✅ AUTO-ORGANIZE: Created folder '\(category)'")
            }
            joke.folder = folderMap[category]
            organized += 1
        }
        
        _ = ensureRecentlyAddedFolder(existingFolders: existingFolders, modelContext: modelContext)
        
        do {
            try modelContext.save()
            print("✅ AUTO-ORGANIZE: Saved changes for \(organized) jokes")
        } catch {
            print("❌ AUTO-ORGANIZE SAVE FAILED: \(error.localizedDescription)")
        }
        
        completion(organized, suggested)
    }
    
    static func getCategories() -> [String] {
        Array(categories.keys).sorted()
    }
    
    static func assignJokeToFolder(_ joke: Joke, folderName: String, modelContext: ModelContext, autoSave: Bool = true) {
        do {
            let descriptor = FetchDescriptor<JokeFolder>()
            var folders = try modelContext.fetch(descriptor)
            if let existing = folders.first(where: { $0.name.caseInsensitiveCompare(folderName) == .orderedSame }) {
                joke.folder = existing
            } else {
                let folder = JokeFolder(name: folderName)
                modelContext.insert(folder)
                joke.folder = folder
                folders.append(folder)
            }
            if autoSave {
                try modelContext.save()
            }
        } catch {
            print("❌ Failed to assign joke: \(error.localizedDescription)")
        }
    }
    
    @discardableResult
    static func ensureRecentlyAddedFolder(
        existingFolders: [JokeFolder],
        modelContext: ModelContext
    ) -> JokeFolder {
        if let folder = existingFolders.first(where: { $0.name == "Recently Added" }) {
            return folder
        }
        let folder = JokeFolder(name: "Recently Added")
        modelContext.insert(folder)
        return folder
    }
    
    // MARK: - Helpers
    private static func scoreCategories(in text: String) -> [TopicMatch] {
        var results: [TopicMatch] = []
        for (category, keywords) in categories {
            let hits = keywords.keywords.filter { text.containsWord($0.0) }
            guard !hits.isEmpty else { continue }
            let weightSum = keywords.keywords.reduce(0.0) { $0 + $1.1 }
            let score = hits.reduce(0.0) { $0 + $1.1 }
            let lengthBoost = min(Double(text.count) / 800.0, 0.15)
            let confidence = min(1.0, (score / max(weightSum, 1.0)) + lengthBoost)
            results.append(TopicMatch(category: category, confidence: confidence, evidence: hits.map { $0.0 }))
        }
        return results.sorted { $0.confidence > $1.confidence }
    }
    
    private static func analyzeStyle(in text: String) -> StyleAnalysis {
        var styleScores: [(String, Int)] = []
        for (tag, cues) in styleCueLexicon {
            let hits = cues.filter { text.contains($0) }
            guard !hits.isEmpty else { continue }
            styleScores.append((tag, hits.count))
        }
        let tags = styleScores.sorted { $0.1 > $1.1 }.map { $0.0 }.prefix(4)
        
        var toneScores: [(String, Int)] = []
        for (tone, cues) in toneKeywords {
            let hits = cues.filter { text.contains($0) }
            if !hits.isEmpty { toneScores.append((tone, hits.count)) }
        }
        let tone = toneScores.sorted { $0.1 > $1.1 }.first?.0
        
        var craftHits: [String] = []
        for (signal, cues) in craftSignalsLexicon {
            if cues.contains(where: { text.contains($0) }) {
                craftHits.append(signal)
            }
        }
        
        var structureScore = 0.0
        if text.contains("setup") { structureScore += 0.15 }
        if text.contains("punchline") { structureScore += 0.15 }
        if text.contains("tag") { structureScore += 0.1 }
        let questionMarks = text.components(separatedBy: "?").count - 1
        structureScore += min(0.2, Double(max(0, questionMarks)) * 0.05)
        structureScore = min(1.0, structureScore)
        
        return StyleAnalysis(tags: Array(tags), tone: tone, craftSignals: craftHits, structureScore: structureScore, hook: tags.first ?? tone)
    }
    
    private static func reasoning(for match: TopicMatch, style: StyleAnalysis) -> String {
        let confidenceText: String
        switch match.confidence {
        case 0.75...: confidenceText = "very confident"
        case 0.5..<0.75: confidenceText = "confident"
        case 0.35..<0.5: confidenceText = "moderately confident"
        default: confidenceText = "suggested"
        }
        if let hook = style.hook {
            return "Matches \(match.evidence.count) cues + \(hook) vibe — \(confidenceText)."
        }
        return "Matches \(match.evidence.count) cues — \(confidenceText)."
    }
    
    private static func hydrate(_ joke: Joke, with matches: [CategoryMatch]) {
        joke.categorizationResults = matches
        if let top = matches.first {
            joke.primaryCategory = top.category
            joke.allCategories = matches.filter { $0.confidence >= multiCategoryThreshold }.map { $0.category }
            var map: [String: Double] = [:]
            matches.forEach { map[$0.category] = $0.confidence }
            joke.categoryConfidenceScores = map
            joke.styleTags = top.styleTags
            joke.comedicTone = top.emotionalTone
            joke.craftNotes = top.craftSignals
            joke.structureScore = top.structureScore ?? 0.0
        }
    }
    
    private static func normalize(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
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
        guard !word.isEmpty else { return false }
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let range = NSRange(startIndex..., in: self)
            return regex.firstMatch(in: self, options: [], range: range) != nil
        } catch {
            return contains(word)
        }
    }
}
