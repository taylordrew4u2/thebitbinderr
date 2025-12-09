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

class AutoOrganizeService {
    // MARK: - Configuration
    private static let confidenceThresholdForAutoOrganize: Double = 0.55
    private static let confidenceThresholdForSuggestion: Double = 0.25
    private static let multiCategoryThreshold: Double = 0.35
    
    // MARK: - Wordplay Detection
    private static let homophoneSets: [[String]] = [
        ["knight", "night"],
        ["write", "right"],
        ["deer", "dear"],
        ["there", "their", "they're"],
        ["would", "wood"],
        ["be", "bee"],
        ["sun", "son"],
        ["one", "won"],
        ["to", "too", "two"],
        ["for", "four", "fore"],
        ["know", "no"],
        ["here", "hear"],
        ["sea", "see"],
        ["break", "brake"],
        ["wear", "where"],
        ["pair", "pear", "pare"],
        ["blue", "blew"],
        ["hour", "our"],
        ["meet", "meat"],
        ["sale", "sail"],
        ["through", "threw"],
        ["red", "read"],
        ["plain", "plane"],
        ["not", "knot"],
        ["hair", "hare"],
        ["waste", "waist"],
        ["piece", "peace"],
        ["be", "bee"],
        ["new", "knew", "gnu"],
        ["board", "bored"]
    ]
    
    private static let doubleMeaningWords: [String: [String]] = [
        "bank": ["financial institution", "river edge"],
        "bark": ["dog sound", "tree covering"],
        "bat": ["flying animal", "sports equipment"],
        "bear": ["animal", "endure"],
        "bill": ["invoice", "duck's beak"],
        "bolt": ["fastener", "run away"],
        "bow": ["weapon", "bend forward"],
        "break": ["pause", "crack"],
        "bug": ["insect", "annoyance"],
        "catch": ["grab", "understand"],
        "change": ["coins", "transform"],
        "charge": ["rush", "price"],
        "close": ["nearby", "shut"],
        "cold": ["temperature", "illness"],
        "cone": ["shape", "ice cream holder"],
        "cross": ["angry", "go across"],
        "date": ["calendar day", "romantic outing"],
        "deck": ["ship platform", "decorate"],
        "die": ["cease living", "cube"],
        "down": ["direction", "unhappy"],
        "draw": ["sketch", "pull"],
        "drill": ["exercise", "tool"],
        "fan": ["enthusiast", "device"],
        "file": ["document", "tool"],
        "fine": ["good", "penalty"],
        "fire": ["flame", "dismiss"],
        "fit": ["exercise routine", "suitable"],
        "flat": ["apartment", "tire"],
        "fly": ["insect", "travel"],
        "form": ["shape", "document"],
        "found": ["discovered", "established"],
        "game": ["sport", "prey"],
        "grave": ["serious", "burial site"],
        "ground": ["earth", "powdered"],
        "hack": ["cough", "break into"],
        "hide": ["conceal", "animal skin"],
        "hit": ["strike", "popular song"],
        "hold": ["grip", "command to wait"],
        "horn": ["instrument", "animal protrusion"],
        "iron": ["metal", "smooth clothing"],
        "jam": ["food spread", "stuck"],
        "jerk": ["rude person", "sudden movement"],
        "joint": ["connection", "place"],
        "joke": ["humor", "person to ridicule"],
        "judge": ["official", "evaluate"],
        "key": ["lock opener", "important"],
        "kick": ["hit with foot", "thrill"],
        "kind": ["type", "compassionate"],
        "knock": ["hit", "criticize"],
        "lead": ["guide", "metal"],
        "leaves": ["departs", "foliage"],
        "left": ["departed", "direction"],
        "lie": ["falsehood", "recline"],
        "light": ["illuminate", "not heavy"],
        "like": ["enjoy", "similar to"],
        "line": ["queue", "fishing equipment"],
        "link": ["connection", "hyperlink"],
        "live": ["reside", "alive"],
        "lock": ["secure", "hair curl"],
        "log": ["wood", "record"],
        "long": ["extended", "desire"],
        "loop": ["circle", "repeat"],
        "loose": ["not tight", "release"],
        "lot": ["piece of land", "many"],
        "mail": ["correspondence", "metal armor"],
        "main": ["primary", "water pipe"],
        "make": ["create", "brand"],
        "mark": ["sign", "target"],
        "match": ["contest", "stick"],
        "mate": ["friend", "chess term"],
        "mean": ["average", "unkind"],
        "measure": ["size", "rhythm"],
        "miss": ["fail to hit", "title for woman"],
        "miss": ["yearn for", "fail to hit"],
        "mold": ["fungus", "shape"],
        "mood": ["emotion", "verb tense"],
        "mouth": ["opening", "river outlet"],
        "move": ["change position", "chess turn"],
        "name": ["title", "specify"],
        "nip": ["pinch", "criticize"],
        "note": ["written message", "musical tone"],
        "object": ["thing", "protest"],
        "order": ["sequence", "command"],
        "organ": ["body part", "musical instrument"],
        "page": ["sheet", "attendant"],
        "pain": ["hurt", "effort"],
        "pair": ["two", "match"],
        "pale": ["light colored", "wooden stake"],
        "palm": ["tree", "hand part"],
        "pan": ["cooking vessel", "criticize"],
        "park": ["outdoor area", "vehicle placement"],
        "part": ["piece", "role"],
        "pass": ["move forward", "succeed"],
        "past": ["history", "gone by"],
        "patch": ["area", "fix"],
        "pause": ["stop", "button"],
        "paw": ["animal foot", "pledge"],
        "peak": ["summit", "reach maximum"],
        "peal": ["sound", "appear"],
        "pen": ["writing tool", "animal enclosure"],
        "permit": ["allow", "document"],
        "plant": ["vegetation", "factory"],
        "plate": ["dish", "thin sheet"],
        "play": ["engage in", "perform"],
        "please": ["make happy", "polite request"],
        "plot": ["plan", "story"],
        "plug": ["stopper", "promote"],
        "pocket": ["pouch", "small"],
        "point": ["tip", "indicate"],
        "pole": ["rod", "geography term"],
        "police": ["law enforcement", "make smooth"],
        "pool": ["water body", "shared resource"],
        "pop": ["sound", "father"],
        "port": ["harbor", "left side"],
        "pose": ["position", "present"],
        "pound": ["hit", "weight unit"],
        "practice": ["exercise", "profession"],
        "pray": ["petition god", "extremely"],
        "present": ["gift", "currently happening"],
        "press": ["push", "news organization"],
        "prey": ["victim", "hunt"],
        "prime": ["first", "excellent"],
        "print": ["publish", "fingerprint"],
        "prize": ["reward", "pry"],
        "produce": ["create", "agricultural goods"],
        "project": ["plan", "protrude"],
        "prone": ["lying down", "inclined"],
        "protest": ["object", "demonstrate"],
        "pull": ["draw", "influence"],
        "pulse": ["heartbeat", "quick movement"],
        "pump": ["device", "push"],
        "punch": ["hit", "tool"],
        "punk": ["style", "hooligan"],
        "pupil": ["student", "eye part"],
        "pursue": ["chase", "engage in"],
        "push": ["shove", "motivation"],
        "put": ["place", "throw"],
        "race": ["competition", "ethnicity"],
        "rack": ["frame", "torture"],
        "raft": ["boat", "large amount"],
        "rail": ["bar", "complain"],
        "rain": ["precipitation", "fall heavily"],
        "raise": ["lift", "increase"],
        "range": ["distance", "stove"],
        "rank": ["position", "smell bad"],
        "rare": ["uncommon", "lightly cooked"],
        "rate": ["speed", "evaluate"],
        "read": ["interpret", "past tense"],
        "real": ["genuine", "very"],
        "realize": ["understand", "make real"],
        "reap": ["harvest", "receive"],
        "rebel": ["resist", "insurgent"],
        "record": ["document", "music disk"],
        "reduce": ["decrease", "convert"],
        "reel": ["spool", "stagger"],
        "reflect": ["mirror", "contemplate"],
        "refuse": ["reject", "garbage"],
        "reign": ["rule", "horse straps"],
        "reject": ["discard", "push back"],
        "relief": ["comfort", "sculpture"],
        "relieve": ["ease", "replace"],
        "rely": ["depend", "place again"],
        "remain": ["stay", "leftovers"],
        "remark": ["comment", "mark again"],
        "remedy": ["cure", "correct"],
        "remember": ["recall", "commemorate"],
        "remind": ["help remember", "put back"],
        "remove": ["take away", "off"],
        "render": ["provide", "depict"],
        "renew": ["restore", "extend"],
        "rent": ["lease", "tear"],
        "repair": ["fix", "go again"],
        "repeat": ["say again", "occur again"],
        "replace": ["substitute", "put back"],
        "reply": ["respond", "fold"],
        "report": ["account", "go back"],
        "repose": ["rest", "arrange"],
        "request": ["ask", "seek again"],
        "require": ["need", "ask for"],
        "rescue": ["save", "take again"],
        "resent": ["dislike", "send back"],
        "reserve": ["keep back", "shy"],
        "reside": ["dwell", "sit again"],
        "resign": ["quit", "sign again"],
        "resist": ["oppose", "stand against"],
        "resolve": ["determine", "solve again"],
        "resort": ["vacation place", "turn to"],
        "respect": ["admiration", "relate to"],
        "respond": ["reply", "answer back"],
        "rest": ["relax", "remainder"],
        "restore": ["repair", "give back"],
        "result": ["outcome", "spring back"],
        "retain": ["keep", "hold back"],
        "retire": ["stop working", "go back"],
        "retreat": ["withdraw", "treat again"],
        "return": ["come back", "give back"],
        "reveal": ["show", "cover again"],
        "revolt": ["rebel", "turn back"],
        "revue": ["entertainment", "review"],
        "rice": ["grain", "pass through sieve"],
        "ride": ["travel on", "joke about"],
        "right": ["correct", "direction"],
        "ring": ["sound", "circle"],
        "riot": ["disturbance", "laugh hard"],
        "ripen": ["mature", "open again"],
        "rise": ["go up", "dough expansion"],
        "risk": ["danger", "hazard"],
        "rival": ["competitor", "equal"],
        "road": ["path", "journey"],
        "roast": ["cook", "ridicule"],
        "rob": ["steal", "deprive"],
        "rock": ["stone", "move back and forth"],
        "roll": ["turn", "bread item"],
        "roof": ["covering", "max out"],
        "room": ["space", "make space"],
        "root": ["plant part", "search"],
        "rope": ["cord", "trick"],
        "rose": ["flower", "past tense of rise"],
        "rough": ["textured", "approximately"],
        "round": ["circular", "series"],
        "rouse": ["wake", "stir"],
        "route": ["path", "way"],
        "row": ["line", "argument"],
        "rub": ["apply friction", "difficulty"],
        "ruin": ["destroy", "remnants"],
        "rule": ["govern", "line"],
        "rum": ["alcohol", "unusual"],
        "run": ["move quickly", "operate"],
        "rush": ["hurry", "plant"],
        "rust": ["oxidation", "disuse"],
        "sack": ["bag", "fire"],
        "sacred": ["holy", "revered"],
        "safe": ["secure", "strongbox"],
        "sage": ["wise person", "herb"],
        "sail": ["canvas", "travel"],
        "sake": ["purpose", "drink"],
        "sale": ["selling", "salt"],
        "salt": ["mineral", "experienced"],
        "sample": ["taste", "subset"],
        "sand": ["particles", "rub smooth"],
        "sane": ["mentally healthy", "rational"],
        "sap": ["tree fluid", "weaken"],
        "sash": ["band", "window frame"],
        "save": ["rescue", "store"],
        "savor": ["enjoy", "taste"],
        "saw": ["cutting tool", "past tense of see"],
        "say": ["speak", "approximately"],
        "scale": ["climb", "size"],
        "scare": ["frighten", "barely"],
        "scatter": ["disperse", "place"]
    ]
    
    // MARK: - Joke Pattern Regex Dictionary
    private static let jokePatterns: [String: [String]] = [
        "Puns": [
            "\\b(pun|wordplay|play on words|double meaning|homophone)\\b",
            "\\b(\\w+)\\s+(sounds like|sounds like a)\\s+\\1",
            "\\b(why|how)\\s+.*\\?.*\\b(because|cause)\\b",
            "\\b(why did)\\s+.*\\?\\s+(to|because)\\b"
        ],
        "Knock-Knock": [
            "^knock\\s+knock",
            "who['\"]?s\\s+there\\?",
            "\\b(interrupting|\\w+ interrupting)\\b"
        ],
        "Dad Jokes": [
            "\\b(dad joke|corny|groan)\\b",
            "\\bi['\"]?m\\s+\\w+\\b.*\\b(nice|great)\\s+to\\s+meet\\s+you\\b",
            "\\b(hi|hello)\\s+\\w+\\b.*\\bi['\"]?m\\s+dad\\b"
        ],
        "One-Liners": [
            "^[^.!?]{10,80}[.!?]$",
            "\\b(one liner|quip|witty)\\b",
            "\\b(so|and|but)\\b.*[.!?]$"
        ],
        "Observational": [
            "\\b(why do|have you ever|isn['\"]?t it|doesn['\"]?t anyone|what['\"]?s with)\\b",
            "\\b(ever notice|funny thing about)\\b"
        ],
        "Roasts": [
            "\\b(roast|insult|you['\"]?re so|look at you|at least)\\b",
            "you['\"]?re\\s+(so\\s+)?\\w+(ugly|stupid|dumb|weird|lazy)"
        ],
        "Self-Deprecating": [
            "\\b(i['\"]?m so|i['\"]?m not|i suck|i['\"]?m terrible|about myself)\\b",
            "\\b(joke['\"]?s on me|my fault|i messed up)\\b"
        ],
        "Anti-Jokes": [
            "\\b(why did.*?\\?.*?other side)\\b",
            "\\b(not really|literally|just)\\s+(a|because)\\b",
            "\\b(anti-?joke|not actually|straightforward)\\b"
        ],
        "Dark Humor": [
            "\\b(death|dying|dead|kill|murder|suicide|grave|funeral|cancer)\\b",
            "\\b(dark|morbid|sick|twisted|horrifying)\\s+(humor|joke)\\b"
        ],
        "Sarcasm": [
            "\\b(oh great|yeah right|sure|definitely|absolutely|totally)\\b",
            "\\b(of course|naturally|obviously)\\b.*[.!?]"
        ],
        "Irony": [
            "\\b(ironically|ironic|unexpectedly|turns out|of course)\\b",
            "\\b(the opposite|exactly|contrary)\\b"
        ],
        "Satire": [
            "\\b(satire|satirical|mock|parody|spoof)\\b",
            "\\b(society|politics|government|corporate|system)\\b"
        ],
        "Anecdotal": [
            "\\b(one time|so there i was|true story|funny thing|this one time)\\b",
            "\\b(my friend|we were|i was|this guy|this girl)\\b"
        ],
        "Riddles": [
            "\\b(what has|what is|who am i|riddle)\\b",
            "\\b(answer is|the answer|trick is)\\b"
        ]
    ]
    
    // MARK: - Setup and Punchline Indicators
    private static let setupIndicators = [
        "so", "this one time", "the other day", "picture this", "imagine",
        "okay so", "alright", "so there i was", "let me tell you", "funny thing",
        "you know", "true story", "no joke", "believe it or not", "get this"
    ]
    
    private static let punchlineIndicators = [
        "turns out", "was actually", "real", "thing is", "plot twist",
        "little did i know", "joke", "punchline", "because", "cause",
        "and then", "so i", "but then", "just kidding", "just joking"
    ]
    
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
