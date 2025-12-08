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
        
        try requestHandler.perform([request])
        
        guard let observations = request.results else {
            print("❌ OCR: No results")
            throw TextRecognitionError.noTextFound
        }
        
        print("🔍 OCR: Found \(observations.count) text blocks")
        
        let recognizedText = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }.joined(separator: "\n")
        
        print("🔍 OCR: Total \(recognizedText.count) chars")
        return recognizedText
    }
    
    static func extractJokes(from text: String) -> [String] {
        print("📝 EXTRACT: Input \(text.count) chars")
        guard !text.isEmpty else {
            print("❌ EXTRACT: Empty")
            return []
        }
        
        let preview = String(text.prefix(100)).replacingOccurrences(of: "\n", with: "\\n")
        print("📝 EXTRACT: Preview: \(preview)")
        
        var jokes: [String] = []
        
        // Method 1: Numbered lists (1. 2. 3.) - PRESERVE NEWLINES!
        print("📝 Method 1: Numbered lists")
        let pattern = #"(?:^|\n)\s*\d+[\.\)]\s*"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) {
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: range)
            print("📝 Found \(matches.count) numbered markers")
            
            if matches.count >= 2 {
                var lastEnd = text.startIndex
                for (i, match) in matches.enumerated() {
                    if let r = Range(match.range, in: text) {
                        if i > 0 {
                            let joke = String(text[lastEnd..<r.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                            if joke.count >= 5 {
                                print("✅ Joke \(i): \(joke.prefix(30))...")
                                jokes.append(joke)
                            }
                        }
                        lastEnd = r.upperBound
                    }
                }
                let final = String(text[lastEnd...]).trimmingCharacters(in: .whitespacesAndNewlines)
                if final.count >= 5 {
                    print("✅ Final: \(final.prefix(30))...")
                    jokes.append(final)
                }
                if !jokes.isEmpty {
                    print("📝 Method 1 SUCCESS: \(jokes.count) jokes")
                    return jokes
                }
            }
        }
        
        // Method 2: Double line breaks
        print("📝 Method 2: Paragraphs")
        let paras = text.components(separatedBy: "\n\n")
        print("📝 Found \(paras.count) paragraphs")
        if paras.count >= 2 {
            for p in paras {
                let t = p.trimmingCharacters(in: .whitespacesAndNewlines)
                if t.count >= 5 {
                    print("✅ Para: \(t.prefix(30))...")
                    jokes.append(t)
                }
            }
            if !jokes.isEmpty {
                print("📝 Method 2 SUCCESS: \(jokes.count) jokes")
                return jokes
            }
        }
        
        // Method 3: Single line breaks
        print("📝 Method 3: Lines")
        let lines = text.components(separatedBy: "\n")
        print("📝 Found \(lines.count) lines")
        if lines.count >= 2 {
            for l in lines {
                let t = l.trimmingCharacters(in: .whitespacesAndNewlines)
                if t.count >= 5 {
                    print("✅ Line: \(t.prefix(30))...")
                    jokes.append(t)
                }
            }
            if !jokes.isEmpty {
                print("📝 Method 3 SUCCESS: \(jokes.count) jokes")
                return jokes
            }
        }
        
        // Method 4: Sentences
        print("📝 Method 4: Sentences")
        let sents = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        var curr = ""
        for s in sents {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty {
                curr += t + ". "
                if curr.count >= 25 {
                    print("✅ Sent: \(curr.prefix(30))...")
                    jokes.append(curr.trimmingCharacters(in: .whitespacesAndNewlines))
                    curr = ""
                }
            }
        }
        if curr.count >= 5 {
            print("✅ Rest: \(curr.prefix(30))...")
            jokes.append(curr.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        if !jokes.isEmpty {
            print("📝 Method 4 SUCCESS: \(jokes.count) jokes")
            return jokes
        }
        
        // Method 5: Whole text
        print("📝 Method 5: Whole text")
        let whole = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if whole.count >= 3 {
            print("✅ Whole: \(whole.prefix(30))...")
            jokes.append(whole)
        }
        
        print("📝 FINAL: \(jokes.count) jokes")
        return jokes
    }
    
    // MARK: - Helper Functions for Title Generation and Validation
    
    /// Generates a title from joke content and validates the joke for completeness
    static func generateTitleFromJoke(_ jokeContent: String) -> (title: String, isValid: Bool) {
        let trimmed = jokeContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Minimum length check - avoid incomplete jokes
        let minimumLength = 15
        if trimmed.count < minimumLength {
            print("⚠️ VALIDATION: Joke too short (\(trimmed.count) chars): \(trimmed.prefix(50))...")
            return (title: "", isValid: false)
        }
        
        // Check for incomplete sentences (ends with only partial punctuation or no punctuation)
        let lastChar = trimmed.last ?? " "
        let endsWithoutPunctuation = !trimmed.hasSuffix(".") && !trimmed.hasSuffix("!") && !trimmed.hasSuffix("?")
        let looksIncomplete = trimmed.contains("...") || trimmed.contains("…") || 
                             (lastChar.isLetter && endsWithoutPunctuation && trimmed.count < 100)
        
        if looksIncomplete {
            print("⚠️ VALIDATION: Incomplete joke detected: \(trimmed.prefix(50))...")
            return (title: "", isValid: false)
        }
        
        // Generate title from first sentence or first 50 characters
        var title = ""
        let endMarkers = CharacterSet(charactersIn: ".!?")
        
        if let firstSentenceEnd = trimmed.rangeOfCharacter(from: endMarkers) {
            title = String(trimmed[trimmed.startIndex..<firstSentenceEnd.lowerBound]).trimmingCharacters(in: .whitespaces)
        } else {
            title = String(trimmed.prefix(50)).trimmingCharacters(in: .whitespaces)
        }
        
        // Ensure title is not empty and is reasonable
        if title.isEmpty || title.count < 5 {
            title = String(trimmed.prefix(50)).trimmingCharacters(in: .whitespaces)
        }
        
        // Fallback: if still too short or doesn't seem like a title, mark as invalid
        if title.count < 5 {
            print("⚠️ VALIDATION: Title too short: \(title)")
            return (title: "", isValid: false)
        }
        
        print("✅ VALIDATION: Valid joke with title: \(title.prefix(40))...")
        return (title: title, isValid: true)
    }
    
    /// Filters out incomplete or invalid jokes
    static func filterValidJokes(_ jokes: [String]) -> [String] {
        return jokes.filter { joke in
            let (_, isValid) = generateTitleFromJoke(joke)
            return isValid
        }
    }
}

enum TextRecognitionError: Error {
    case invalidImage
    case noTextFound
    case recognitionFailed
}
