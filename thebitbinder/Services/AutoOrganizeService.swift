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

// MARK: - Joke Structure Analysis
struct JokeStructure {
    let hasSetup: Bool
    let hasPunchline: Bool
    let format: JokeFormat
    let wordplayScore: Double
    let setupLineCount: Int
    let punchlineLineCount: Int
    let questionAnswerPattern: Bool
    let storyTwistPattern: Bool
    let oneLiners: Int
    let dialogueCount: Int
    
    var structureConfidence: Double {
        var score = 0.0
        if hasSetup { score += 0.2 }
        if hasPunchline { score += 0.2 }
        score += min(wordplayScore * 0.2, 0.2)
        if questionAnswerPattern { score += 0.15 }
        if storyTwistPattern { score += 0.15 }
        return min(score, 1.0)
    }
}

enum JokeFormat {
    case questionAnswer
    case storyTwist
    case oneLiner
    case dialogue
    case sequential
    case unknown
}

// MARK: - Pattern Match Result
struct PatternMatchResult {
    let category: String
    let patterns: [String]
    let confidence: Double
}

// Type aliases for reconstructed text and templates
typealias ReconstructedText = (original: String, reconstructed: String, confidenceScore: Double, changesApplied: [String])
typealias JokeTemplate = (pattern: String, commonStructures: [String], keywordSignatures: [String], successRate: Double, usageCount: Int, successCount: Int)

struct CoherenceAnalysis {
    let score: Double
    let issues: [String]
    let needsManualReview: Bool
    let suggestedCategory: String?
}

// Wordplay detection helpers
let homophoneSets: [[String]] = [
    ["to", "too", "two"],
    ["be", "bee"],
    ["see", "sea"],
    ["here", "hear"],
    ["write", "right"],
    ["mail", "male"],
    ["knight", "night"]
]

let doubleMeaningWords: [(String, String)] = [
    ("bark", "tree coating or dog sound"),
    ("bank", "financial or river side"),
    ("can", "is able or container"),
    ("date", "calendar or romantic outing"),
    ("fair", "just or carnival")
]

// Placeholder for jokePatterns used in pattern matching
private let jokePatterns: [String: [String]] = [:]

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
        let structure = analyzeJokeStructure(normalized)
        let topicMatches = scoreCategories(in: normalized)
        var matches: [CategoryMatch] = []
        
        for match in topicMatches where match.confidence >= confidenceThresholdForSuggestion {
            matches.append(
                CategoryMatch(
                    category: match.category,
                    confidence: match.confidence,
                    reasoning: reasoning(for: match, style: style, structure: structure),
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
    
    
    // MARK: - Advanced Text Reconstruction System
    
    /// Reconstructs messy PDF-extracted text with context-aware sentence completion
    static func reconstructText(_ text: String) -> ReconstructedText {
        var reconstructed = text
        var changes: [String] = []
        
        // Step 1: Fix truncated words with common joke vocabulary
        let completions = fixTruncatedWords(&reconstructed)
        changes.append(contentsOf: completions)
        
        // Step 2: Detect and repair incomplete question-answer pairs
        let qaRepairs = repairIncompleteQA(&reconstructed)
        changes.append(contentsOf: qaRepairs)
        
        // Step 3: Detect and bridge fragmented joke parts
        let bridgeRepairs = bridgeJokeFragments(&reconstructed)
        changes.append(contentsOf: bridgeRepairs)
        
        // Step 4: Reconstruct sentences that are cut off mid-thought
        let sentenceRepairs = completeTruncatedSentences(&reconstructed)
        changes.append(contentsOf: sentenceRepairs)
        
        let confidenceScore = calculateReconstructionConfidence(changes.count, textLength: text.count)
        
        return ReconstructedText(
            original: text,
            reconstructed: reconstructed,
            confidenceScore: confidenceScore,
            changesApplied: changes
        )
    }
    
    /// Fixes truncated words using common joke vocabulary patterns
    private static func fixTruncatedWords(_ text: inout String) -> [String] {
        var changes: [String] = []
        
        let commonJokeWords = [
            "qu": "question", "answ": "answer", "punchli": "punchline",
            "setup": "setup", "joke": "joke", "laugh": "laugh",
            "funny": "funny", "hilari": "hilarious", "witty": "witty",
            "sarcas": "sarcasm", "ironically": "ironically", "obviously": "obviously",
            "unexpected": "unexpected", "surprising": "surprising", "shock": "shocking",
            "terrible": "terrible", "awful": "awful", "amazing": "amazing"
        ]
        
        for (fragment, complete) in commonJokeWords {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: fragment))(?![a-z])"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                let matches = regex.matches(in: text, range: range)
                
                if !matches.isEmpty {
                    text = regex.stringByReplacingMatches(in: text, range: range, withTemplate: complete)
                    changes.append("Fixed '\(fragment)' → '\(complete)' (\(matches.count)x)")
                }
            }
        }
        
        return changes
    }
    
    /// Repairs incomplete question-answer joke pairs
    private static func repairIncompleteQA(_ text: inout String) -> [String] {
        var changes: [String] = []
        
        // Detect "Why/How/What... ?" without answer
        let qaPattern = "(?i)(why|how|what|who|where|when)\\s+[^?]*\\?(?!\\s*[a-z])"
        if let regex = try? NSRegularExpression(pattern: qaPattern) {
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, range: range)
            
            for match in matches {
                if let matchRange = Range(match.range, in: text) {
                    let question = String(text[matchRange])
                    let suggestion = generateQAPunchline(for: question)
                    if !suggestion.isEmpty {
                        text.replaceSubrange(matchRange, with: question + " " + suggestion)
                        changes.append("Repaired incomplete Q&A: added punchline")
                    }
                }
            }
        }
        
        return changes
    }
    
    /// Generates likely punchline for incomplete Q&A jokes
    private static func generateQAPunchline(for question: String) -> String {
        let questionLower = question.lowercased()
        
        // Common Q&A joke patterns
        let patterns: [String: String] = [
            "why did": "Because it wanted to.",
            "how do you": "Very carefully.",
            "what do you call": "I don't know, you tell me.",
            "where did": "Everywhere.",
            "when do you": "All the time."
        ]
        
        for (pattern, reply) in patterns {
            if questionLower.contains(pattern) {
                return reply
            }
        }
        
        return ""
    }
    
    /// Bridges fragmented joke parts across line breaks or page boundaries
    private static func bridgeJokeFragments(_ text: inout String) -> [String] {
        var changes: [String] = []
        
        // Remove excessive line breaks that fragment jokes
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        var merged: [String] = []
        var currentLine = ""
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // If line ends without punctuation and next line is continuation
            if !currentLine.isEmpty && !currentLine.hasSuffix(".") && !currentLine.hasSuffix("?") && !currentLine.hasSuffix("!") {
                currentLine += " " + trimmed
            } else {
                if !currentLine.isEmpty {
                    merged.append(currentLine)
                }
                currentLine = trimmed
            }
        }
        
        if !currentLine.isEmpty {
            merged.append(currentLine)
        }
        
        let newText = merged.joined(separator: "\n")
        if newText != text {
            changes.append("Bridged fragmented lines: \(lines.count) → \(merged.count) lines")
            text = newText
        }
        
        return changes
    }
    
    /// Completes sentences that are cut off mid-thought
    private static func completeTruncatedSentences(_ text: inout String) -> [String] {
        var changes: [String] = []
        
        let sentences = text.split(whereSeparator: { ".!?".contains($0) }).map { String($0).trimmingCharacters(in: .whitespaces) }
        
        for (index, sentence) in sentences.enumerated() {
            // Check for incomplete sentences (no verb or object)
            let words = sentence.split(separator: " ")
            
            // If sentence is very short and doesn't end with common joke endings
            if words.count < 3 && !sentence.isEmpty {
                let nextSentence = index + 1 < sentences.count ? sentences[index + 1] : ""
                if !nextSentence.isEmpty && shouldMergeSentences(sentence, nextSentence) {
                    let merged = sentence + " " + nextSentence
                    text = text.replacingOccurrences(of: sentence, with: merged)
                    changes.append("Merged incomplete sentence with next line")
                }
            }
        }
        
        return changes
    }
    
    /// Determines if two sentence fragments should be merged
    private static func shouldMergeSentences(_ first: String, _ second: String) -> Bool {
        // Don't merge if first sentence looks complete
        if first.hasSuffix("!") || first.hasSuffix("?") {
            return false
        }
        
        // Merge if second sentence continues the thought
        let continuationPatterns = ["because", "so", "that's", "which", "who", "what", "where", "when", "how", "why"]
        let startsWithContinuation = continuationPatterns.contains { second.lowercased().starts(with: $0) }
        
        return startsWithContinuation || (first.count > 0 && !first.last!.isLetter)
    }
    
    /// Calculates reconstruction confidence score
    private static func calculateReconstructionConfidence(_ changesCount: Int, textLength: Int) -> Double {
        // Fewer changes = higher confidence
        let changeRatio = Double(changesCount) / max(Double(textLength) / 50, 1)
        
        // Very high change ratio indicates text was severely corrupted
        if changeRatio > 0.5 {
            return 0.6  // Lower confidence for heavily corrupted text
        } else if changeRatio > 0.2 {
            return 0.8
        } else {
            return 0.95
        }
    }
    
    // MARK: - Multi-Layer Pattern Matching System
    
    /// 3-tier pattern matching: strict → fuzzy → semantic
    static func matchPatternWithFallback(_ text: String, category: String) -> Double {
        // Tier 1: Strict regex matching (current approach)
        let strictScore = matchPatternStrict(text, category: category)
        if strictScore > 0.7 {
            return strictScore
        }
        
        // Tier 2: Fuzzy matching for similar text
        let fuzzyScore = matchPatternFuzzy(text, category: category)
        if fuzzyScore > 0.6 {
            return fuzzyScore * 0.9  // Slight confidence penalty
        }
        
        // Tier 3: Semantic matching using joke structure heuristics
        let semanticScore = matchPatternSemantic(text, category: category)
        return semanticScore * 0.8  // Confidence penalty for semantic matching
    }
    
    /// Tier 1: Strict regex pattern matching
    private static func matchPatternStrict(_ text: String, category: String) -> Double {
        guard let patterns = jokePatterns[category] else { return 0 }
        
        var score: Double = 0.0
        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let range = NSRange(text.startIndex..., in: text)
                if regex.firstMatch(in: text, range: range) != nil {
                    score += 0.25
                }
            } catch {
                continue
            }
        }
        
        return min(score / Double(patterns.count), 1.0)
    }
    
    /// Tier 2: Fuzzy matching (80% similarity) for garbled text
    private static func matchPatternFuzzy(_ text: String, category: String) -> Double {
        guard let patterns = jokePatterns[category] else { return 0 }
        let lowerText = text.lowercased()
        
        var matches = 0
        for pattern in patterns {
            let cleanPattern = pattern
                .replacingOccurrences(of: "\\b", with: "")
                .replacingOccurrences(of: "\\?", with: "")
                .lowercased()
            
            // Check if ~80% of pattern words exist in text
            let patternWords = cleanPattern.split(separator: " ")
            let matchingWords = patternWords.filter { word in
                lowerText.contains(String(word))
            }
            
            let similarity = Double(matchingWords.count) / Double(patternWords.count)
            if similarity >= 0.8 {
                matches += 1
            }
        }
        
        return Double(matches) / Double(patterns.count)
    }
    
    /// Tier 3: Semantic matching using joke structure heuristics
    private static func matchPatternSemantic(_ text: String, category: String) -> Double {
        let structure = analyzeJokeStructure(text)
        var score: Double = 0.0
        
        // Category-specific semantic rules
        switch category {
        case "Puns":
            score = structure.wordplayScore
        case "One-Liners":
            score = structure.format == JokeFormat.oneLiner ? 0.9 : 0.3
        case "Knock-Knock":
            score = text.lowercased().contains("knock knock") ? 0.9 : 0.2
        case "Observational":
            score = text.lowercased().contains("why do") || text.lowercased().contains("have you") ? 0.8 : 0.3
        case "Anecdotal":
            score = structure.format == JokeFormat.storyTwist || structure.format == JokeFormat.sequential ? 0.8 : 0.3
        case "Dark Humor":
            let darkWords = ["death", "suicide", "grave", "dying", "murder"]
            let hasDarkWords = darkWords.contains { text.lowercased().contains($0) }
            score = hasDarkWords ? 0.85 : 0.2
        default:
            score = 0.3
        }
        
        return score
    }
    
    /// Pattern bridging - connects fragmented joke parts across boundaries
    static func bridgePatternFragments(_ fragments: [String]) -> String {
        var result = ""
        
        for (index, fragment) in fragments.enumerated() {
            result += fragment
            
            // Add connecting punctuation/words between fragments if needed
            if index < fragments.count - 1 {
                let trimmedCurrent = fragment.trimmingCharacters(in: .whitespaces)
                let trimmedNext = fragments[index + 1].trimmingCharacters(in: .whitespaces)
                
                if !trimmedCurrent.isEmpty && !trimmedNext.isEmpty {
                    let needsSpace = !trimmedCurrent.hasSuffix(" ") && !trimmedNext.hasPrefix(" ")
                    if needsSpace {
                        result += " "
                    }
                }
            }
        }
        
        return result
    }
    
    // MARK: - Self-Learning Dictionary System
    
    /// Stores learned joke templates from successful categorizations
    private static var jokeTemplateLibrary: [String: JokeTemplate] = [:]
    
    /// Template matcher - identifies common joke skeletons even with missing words
    static func matchJokeTemplate(_ text: String) -> (category: String, confidence: Double) {
        let normalized = text.lowercased()
        var bestMatch = ("Other", 0.0)
        
        for (category, template) in jokeTemplateLibrary {
            var score: Double = 0.0
            
            // Check how many template structures are found
            for structure in template.commonStructures {
                if normalized.contains(structure) {
                    score += 0.25
                }
            }
            
            // Check for keyword signatures
            for keyword in template.keywordSignatures {
                if normalized.contains(keyword) {
                    score += 0.15
                }
            }
            
            // Apply success rate multiplier
            let confidenceScore = (score / Double(template.commonStructures.count + template.keywordSignatures.count)) * template.successRate
            
            if confidenceScore > bestMatch.1 {
                bestMatch = (category, confidenceScore)
            }
        }
        
        return bestMatch
    }
    
    /// Updates learned templates based on successful categorizations
    static func updateJokeTemplate(category: String, content: String, success: Bool) {
        let normalized = content.lowercased()
        let words = normalized.split(separator: " ").map { String($0) }
        
        // Extract common structures and keywords
        let structures = extractCommonStructures(from: normalized)
        let keywords = Array(Set(words.filter { $0.count > 4 })).prefix(5).map { String($0) }
        
        let template = JokeTemplate(
            pattern: category,
            commonStructures: structures,
            keywordSignatures: keywords,
            successRate: 0.7,
            usageCount: 1,
            successCount: success ? 1 : 0
        )
        
        jokeTemplateLibrary[category] = template
    }
    
    /// Extracts common structural patterns from joke text
    private static func extractCommonStructures(from text: String) -> [String] {
        var structures: [String] = []
        
        // Extract opening phrases
        let openingPatterns = ["why", "how", "what", "knock knock", "so there", "one time"]
        for pattern in openingPatterns {
            if text.contains(pattern) {
                structures.append(pattern)
            }
        }
        
        // Extract transition words
        let transitions = ["because", "then", "turns out", "but", "actually", "just"]
        for transition in transitions {
            if text.contains(transition) {
                structures.append(transition)
            }
        }
        
        return structures
    }
    
    // MARK: - Intelligent Context Preservation
    
    /// Analyzes coherence of extracted text and detects nonsensical extractions
    static func analyzeCoherence(_ text: String) -> CoherenceAnalysis {
        var score: Double = 1.0
        var issues: [String] = []
        var suggestedCategory: String? = nil
        
        let words = text.split(separator: " ")
        
        // Check for excessive repetition (OCR artifact)
        let uniqueWords = Set(words.map { $0.lowercased() })
        let repetitionRatio = Double(words.count) / Double(uniqueWords.count)
        if repetitionRatio > 3 {
            score -= 0.3
            issues.append("Excessive word repetition (OCR artifact)")
        }
        
        // Check for nonsensical word sequences
        let nonsensePatterns = ["the the", "a a", "and and", "  ", "___"]
        for pattern in nonsensePatterns {
            if text.contains(pattern) {
                score -= 0.15
                issues.append("Nonsensical sequences detected")
                break
            }
        }
        
        // Check for missing punctuation that breaks structure
        let sentences: [String] = {
            let pattern = "[^.!?]+"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [text] }
            let range = NSRange(text.startIndex..., in: text)
            return regex.matches(in: text, range: range).compactMap { Range($0.range, in: text) }.map { String(text[$0]).trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        }()
        if sentences.count < 2 && text.count > 100 {
            score -= 0.2
            issues.append("Missing punctuation breaks joke structure")
        }
        
        // Check for unbalanced parentheses/quotes (OCR errors)
        let openParens = text.filter { $0 == "(" }.count
        let closeParens = text.filter { $0 == ")" }.count
        if abs(openParens - closeParens) > 2 {
            score -= 0.15
            issues.append("Unbalanced punctuation detected")
        }
        
        // Check coherence against joke structure
        let structure = analyzeJokeStructure(text)
        if structure.structureConfidence < 0.2 && text.count > 50 {
            score -= 0.2
            issues.append("Poor joke structure - may be corrupted")
        }
        
        // Determine if manual review is needed
        let needsReview = score < 0.6 || issues.count > 2
        
        // Suggest category based on what we could parse
        if !issues.isEmpty {
            suggestedCategory = tryBestGuessCategory(text)
        }
        
        return CoherenceAnalysis(
            score: max(score, 0.1),
            issues: issues,
            needsManualReview: needsReview,
            suggestedCategory: suggestedCategory
        )
    }
    
    /// Detects where one joke ends and another begins in continuous text
    static func detectJokeBoundaries(_ text: String) -> [NSRange] {
        var boundaries: [NSRange] = []
        
        let lines = text.split(separator: "\n", omittingEmptySubsequences: true)
        var position = 0
        
        for (index, line) in lines.enumerated() {
            let lineStr = String(line)
            
            // Boundary indicators
            let boundaryPatterns = [
                "^\\d+\\.", // "1.", "2.", etc.
                "^[A-Z]{2,}:", // "SETUP:", "PUNCHLINE:", etc.
                "^---+$", // Separator line
                "^\\*\\*\\*", // Asterisk separator
            ]
            
            var isBoundary = false
            for pattern in boundaryPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let range = NSRange(lineStr.startIndex..., in: lineStr)
                    if regex.firstMatch(in: lineStr, range: range) != nil {
                        isBoundary = true
                        break
                    }
                }
            }
            
            if isBoundary && index > 0 {
                boundaries.append(NSRange(location: position, length: 0))
            }
            
            position += lineStr.count + 1
        }
        
        return boundaries
    }
    
    // MARK: - Enhanced Error Recovery
    
    /// Best-guess categorizer for severely corrupted text
    static func tryBestGuessCategory(_ text: String) -> String {
        let lowerText = text.lowercased()
        
        // Key signature detection
        let signatures: [String: [String]] = [
            "Puns": ["pun", "wordplay", "sounds", "double"],
            "Dark Humor": ["death", "suicide", "grave", "dying"],
            "Knock-Knock": ["knock knock", "who's there"],
            "One-Liners": ["line", "quick", "short"],
            "Observational": ["why do", "have you", "isn't it"],
            "Roasts": ["roast", "insult", "you're so"],
            "Sarcasm": ["yeah right", "sure", "of course"]
        ]
        
        var bestScore = ("Other", 0.0)
        
        for (category, keywords) in signatures {
            let matchCount = keywords.filter { lowerText.contains($0) }.count
            let score = Double(matchCount) / Double(keywords.count)
            
            if score > bestScore.1 {
                bestScore = (category, score)
            }
        }
        
        return bestScore.0
    }
    
    /// Suggests most likely complete version of truncated joke
    static func suggestJokeRepair(_ truncated: String) -> String {
        let structure = analyzeJokeStructure(truncated)
        var suggestion = truncated
        
        // If setup detected but no punchline, add generic punchline
        if structure.hasSetup && !structure.hasPunchline {
            suggestion += " That's why it's funny."
        }
        
        // If question detected but no answer, add pause
        if truncated.contains("?") && !truncated.contains("because") {
            suggestion = truncated.replacingOccurrences(of: "?", with: "? [pause for laughter]")
        }
        
        return suggestion
    }
    
    // MARK: - Enhanced Fragment Handling for Wordplay
    
    /// Enhanced wordplay detection that works with fragmented text
    static func detectWordplayInFragments(_ fragments: [String]) -> Double {
        var score: Double = 0.0
        let fullText = fragments.joined(separator: " ")
        
        // Check homophones across fragments
        for homoSet in homophoneSets {
            var foundCount = 0
            for homo in homoSet {
                if fullText.lowercased().contains(homo) {
                    foundCount += 1
                }
            }
            if foundCount >= 2 {
                score += 0.3
                break
            }
        }
        
        // Check double meanings across fragments
        var meaningCount = 0
        for (word, _) in doubleMeaningWords {
            if fullText.lowercased().contains(word) {
                meaningCount += 1
            }
        }
        score += min(Double(meaningCount) * 0.1, 0.4)
        
        return min(score, 1.0)
    }
    
    // MARK: - Helpers
    
    /// Analyzes joke structure heuristics for a given text
    private static func analyzeJokeStructure(_ text: String) -> JokeStructure {
        let lower = text.lowercased()
        let hasQ = lower.contains("?") || lower.contains("why ") || lower.contains("what ") || lower.contains("how ")
        let hasAnswerIndicators = lower.contains("because") || lower.contains("so ") || lower.contains("that's why")
        let lines = text.split(separator: "\n").map { String($0) }
        let setupLines = lines.prefix { !$0.contains("?") }.count
        let punchLines = max(1, lines.count - setupLines)

        // Wordplay heuristic using homophones/double meanings already defined
        var wordplay = 0.0
        for set in homophoneSets {
            let present = set.filter { lower.contains($0) }
            if present.count >= 2 { wordplay += 0.5; break }
        }
        for (word, _) in doubleMeaningWords { if lower.contains(word) { wordplay += 0.1 } }
        wordplay = min(wordplay, 1.0)

        // Determine format
        let format: JokeFormat
        if lower.contains("knock knock") { format = .sequential }
        else if hasQ && hasAnswerIndicators { format = .questionAnswer }
        else if lines.count <= 2 && text.count < 140 { format = .oneLiner }
        else if lower.contains("\n") && (lower.contains("then ") || lower.contains("turns out") || lower.contains("but ")) { format = .storyTwist }
        else { format = .unknown }

        return JokeStructure(
            hasSetup: hasQ || setupLines > 0,
            hasPunchline: hasAnswerIndicators || punchLines > 0,
            format: format,
            wordplayScore: wordplay,
            setupLineCount: setupLines,
            punchlineLineCount: punchLines,
            questionAnswerPattern: format == .questionAnswer,
            storyTwistPattern: format == .storyTwist,
            oneLiners: format == .oneLiner ? 1 : 0,
            dialogueCount: lower.components(separatedBy: ": ").count - 1
        )
    }
    
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
    
    private static func reasoning(for match: TopicMatch, style: StyleAnalysis, structure: JokeStructure) -> String {
        let confidenceText: String
        switch match.confidence {
        case 0.75...: confidenceText = "very confident"
        case 0.5..<0.75: confidenceText = "confident"
        case 0.35..<0.5: confidenceText = "moderately confident"
        default: confidenceText = "suggested"
        }
        
        var details: [String] = []
        
        if let hook = style.hook {
            details.append("\(hook) vibe")
        }
        
        if structure.structureConfidence > 0.6 {
            details.append("strong structure")
        }
        
        if structure.wordplayScore > 0.5 {
            details.append("wordplay detected")
        }
        
        if !details.isEmpty {
            return "Matches \(match.evidence.count) cues, \(details.joined(separator: ", ")) — \(confidenceText)."
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

