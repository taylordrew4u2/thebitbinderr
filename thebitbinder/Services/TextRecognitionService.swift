//
//  TextRecognitionService.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/2/25.
//

import UIKit
import Vision
import VisionKit

class TextRecognitionService {
    
    // MARK: - Enhanced OCR
    
    static func recognizeText(from image: UIImage) async throws -> String {
        print("🔍 OCR: Starting recognition, image: \(image.size.width)x\(image.size.height)")
        
        guard let cgImage = image.cgImage else {
            print("❌ OCR: Failed to get CGImage")
            throw TextRecognitionError.invalidImage
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US"]
        
        try requestHandler.perform([request])
        
        guard let observations = request.results else {
            print("❌ OCR: No results")
            throw TextRecognitionError.noTextFound
        }
        
        print("🔍 OCR: Found \(observations.count) text blocks")
        
        // Enhanced text extraction with better spacing
        let recognizedText = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }.joined(separator: "\n")
        
        // Clean up common OCR errors
        let cleanedText = cleanOCRErrors(recognizedText)
        
        print("🔍 OCR: Total \(cleanedText.count) chars (cleaned)")
        return cleanedText
    }
    
    // MARK: - OCR Error Correction
    
    private static func cleanOCRErrors(_ text: String) -> String {
        var cleaned = text
        
        // Common OCR mistakes
        cleaned = cleaned.replacingOccurrences(of: "l'm", with: "I'm")
        cleaned = cleaned.replacingOccurrences(of: "l'll", with: "I'll")
        cleaned = cleaned.replacingOccurrences(of: "l've", with: "I've")
        cleaned = cleaned.replacingOccurrences(of: "0f", with: "of")
        cleaned = cleaned.replacingOccurrences(of: "th1s", with: "this")
        cleaned = cleaned.replacingOccurrences(of: "teh", with: "the")
        
        // Remove excessive whitespace while preserving paragraph breaks
        cleaned = cleaned.replacingOccurrences(of: #"\n\n\n+"#, with: "\n\n", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
        
        return cleaned
    }
    
    // MARK: - Smart Joke Extraction
    
    static func extractJokes(from text: String) -> [String] {
        print("📝 EXTRACT: Input \(text.count) chars")
        guard !text.isEmpty else {
            print("❌ EXTRACT: Empty")
            return []
        }
        
        var rawJokes: [String] = []
        
        // Method 1: Numbered lists (1. 2. 3. or 1) 2) 3))
        if let numberedJokes = extractNumberedJokes(from: text), !numberedJokes.isEmpty {
            rawJokes = numberedJokes
            print("📝 Method 1 (Numbered): Found \(rawJokes.count) jokes")
        }
        // Method 2: Bullet points (• - *)
        else if let bulletJokes = extractBulletedJokes(from: text), !bulletJokes.isEmpty {
            rawJokes = bulletJokes
            print("📝 Method 2 (Bullets): Found \(rawJokes.count) jokes")
        }
        // Method 3: Double line breaks (paragraphs)
        else if let paragraphJokes = extractParagraphJokes(from: text), !paragraphJokes.isEmpty {
            rawJokes = paragraphJokes
            print("📝 Method 3 (Paragraphs): Found \(rawJokes.count) jokes")
        }
        // Method 4: Single jokes (whole text)
        else {
            rawJokes = [text.trimmingCharacters(in: .whitespacesAndNewlines)]
            print("📝 Method 4 (Whole): Treating as single joke")
        }
        
        // Quality filter and deduplicate
        let qualityJokes = filterAndScoreJokes(rawJokes)
        print("📝 FINAL: \(qualityJokes.count) high-quality jokes")
        
        return qualityJokes
    }
    
    private static func extractNumberedJokes(from text: String) -> [String]? {
        let pattern = #"(?:^|\n)\s*(\d+)[\.\)]\s*"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        
        guard matches.count >= 2 else { return nil }
        
        var jokes: [String] = []
        var lastEnd = text.startIndex
        
        for (i, match) in matches.enumerated() {
            if let r = Range(match.range, in: text) {
                if i > 0 {
                    let joke = String(text[lastEnd..<r.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if joke.count >= 10 {
                        jokes.append(joke)
                    }
                }
                lastEnd = r.upperBound
            }
        }
        
        // Add final joke
        let final = String(text[lastEnd...]).trimmingCharacters(in: .whitespacesAndNewlines)
        if final.count >= 10 {
            jokes.append(final)
        }
        
        return jokes.isEmpty ? nil : jokes
    }
    
    private static func extractBulletedJokes(from text: String) -> [String]? {
        let pattern = #"(?:^|\n)\s*[•\-\*]\s+"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        
        guard matches.count >= 2 else { return nil }
        
        var jokes: [String] = []
        var lastEnd = text.startIndex
        
        for (i, match) in matches.enumerated() {
            if let r = Range(match.range, in: text) {
                if i > 0 {
                    let joke = String(text[lastEnd..<r.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if joke.count >= 10 {
                        jokes.append(joke)
                    }
                }
                lastEnd = r.upperBound
            }
        }
        
        let final = String(text[lastEnd...]).trimmingCharacters(in: .whitespacesAndNewlines)
        if final.count >= 10 {
            jokes.append(final)
        }
        
        return jokes.isEmpty ? nil : jokes
    }
    
    private static func extractParagraphJokes(from text: String) -> [String]? {
        let paragraphs = text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 20 }
        
        return paragraphs.count >= 2 ? paragraphs : nil
    }
    
    // MARK: - Quality Filtering
    
    private static func filterAndScoreJokes(_ jokes: [String]) -> [String] {
        var scoredJokes: [(joke: String, score: Int)] = []
        
        for joke in jokes {
            let score = calculateJokeQuality(joke)
            if score >= 3 { // Minimum quality threshold
                scoredJokes.append((joke, score))
            }
        }
        
        // Remove duplicates (similar jokes)
        let deduped = removeDuplicates(scoredJokes.map { $0.joke })
        
        return deduped
    }
    
    private static func calculateJokeQuality(_ joke: String) -> Int {
        var score = 5 // Base score
        
        // Length check
        if joke.count < 15 {
            score -= 3
        } else if joke.count > 50 {
            score += 1
        }
        
        // Has proper ending?
        if joke.hasSuffix(".") || joke.hasSuffix("!") || joke.hasSuffix("?") {
            score += 2
        }
        
        // Has setup/punchline structure?
        if joke.contains("?") && !joke.hasSuffix("?") {
            score += 2 // Likely setup + punchline
        }
        
        // Avoid fragments
        let wordCount = joke.components(separatedBy: .whitespaces).count
        if wordCount < 3 {
            score -= 2
        }
        
        // Avoid titles/headers (all caps, very short)
        if joke == joke.uppercased() && joke.count < 30 {
            score -= 3
        }
        
        return score
    }
    
    private static func removeDuplicates(_ jokes: [String]) -> [String] {
        var unique: [String] = []
        
        for joke in jokes {
            let normalized = joke.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let isDuplicate = unique.contains { existing in
                let existingNorm = existing.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                return similarity(normalized, existingNorm) > 0.85
            }
            
            if !isDuplicate {
                unique.append(joke)
            }
        }
        
        return unique
    }
    
    private static func similarity(_ s1: String, _ s2: String) -> Double {
        let len1 = s1.count
        let len2 = s2.count
        
        if len1 == 0 || len2 == 0 { return 0.0 }
        if s1 == s2 { return 1.0 }
        
        let maxLen = max(len1, len2)
        let minLen = min(len1, len2)
        
        // Simple similarity based on length and prefix
        if s1.hasPrefix(String(s2.prefix(minLen / 2))) {
            return Double(minLen) / Double(maxLen)
        }
        
        return 0.0
    }
    
    // MARK: - Smart Title Generation
    
    static func generateTitleFromJoke(_ jokeContent: String) -> (title: String, isValid: Bool) {
        let trimmed = jokeContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Minimum length check
        guard trimmed.count >= 15 else {
            print("⚠️ Joke too short: \(trimmed.count) chars")
            return (title: "", isValid: false)
        }
        
        // Generate smart title
        let title = extractSmartTitle(from: trimmed)
        
        // Validate
        let isValid = validateJoke(trimmed)
        
        if !isValid {
            print("⚠️ Invalid joke: \(trimmed.prefix(50))...")
        }
        
        return (title: title, isValid: isValid)
    }
    
    private static func extractSmartTitle(from joke: String) -> String {
        // Method 1: Use first question as title (setup)
        if let questionMark = joke.firstIndex(of: "?") {
            let title = String(joke[...questionMark]).trimmingCharacters(in: .whitespaces)
            if title.count >= 10 && title.count <= 100 {
                return title
            }
        }
        
        // Method 2: First sentence
        let endMarkers = CharacterSet(charactersIn: ".!?")
        if let firstEnd = joke.rangeOfCharacter(from: endMarkers) {
            let title = String(joke[joke.startIndex..<firstEnd.lowerBound]).trimmingCharacters(in: .whitespaces)
            if title.count >= 10 && title.count <= 100 {
                return title
            }
        }
        
        // Method 3: First line
        if let firstNewline = joke.firstIndex(of: "\n") {
            let title = String(joke[..<firstNewline]).trimmingCharacters(in: .whitespaces)
            if title.count >= 10 && title.count <= 100 {
                return title
            }
        }
        
        // Method 4: First 60 chars
        let title = String(joke.prefix(60)).trimmingCharacters(in: .whitespaces)
        if title.count >= 60 {
            return title + "..."
        }
        
        return title
    }
    
    private static func validateJoke(_ joke: String) -> Bool {
        // Too short
        if joke.count < 15 {
            return false
        }
        
        // Too few words
        let wordCount = joke.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.count
        if wordCount < 3 {
            return false
        }
        
        // Looks like a header/title (short and all caps)
        if joke.count < 30 && joke == joke.uppercased() {
            return false
        }
        
        // Missing ending punctuation on longer jokes
        let hasEnding = joke.hasSuffix(".") || joke.hasSuffix("!") || joke.hasSuffix("?")
        if joke.count > 100 && !hasEnding {
            return false
        }
        
        return true
    }
    
    // MARK: - Auto-Categorization
    
    static func suggestCategory(for jokeContent: String) -> String? {
        // Create a temporary joke-like object for categorization
        let tempJoke = TempJoke(title: "", content: jokeContent)
        return AutoOrganizeService.autoCategorize(tempJoke)
    }
}

// Temporary joke struct for categorization
private struct TempJoke: Categorizable {
    let title: String
    let content: String
}

enum TextRecognitionError: Error {
    case invalidImage
    case noTextFound
    case recognitionFailed
}

extension TextRecognitionService {
    /// Filters out incomplete or invalid jokes
    static func filterValidJokes(_ jokes: [String]) -> [String] {
        return jokes.filter { joke in
            let (_, isValid) = generateTitleFromJoke(joke)
            return isValid
        }
    }
}
