//
//  GymService.swift
//  thebitbinder
//
//  Created by Taylor Drew on 2/1/26.
//

import Foundation

class GymService {
    static let shared = GymService()
    
    // MARK: - Outsider Questions by Topic
    // These are naive, uninformed questions that real people ask
    
    private let outsiderQuestionsByTopic: [String: [String]] = [
        "TV": [
            "Why do TVs still need remotes if they're 'smart'?",
            "Why is every TV louder than real life?",
            "Why does the TV know what I like better than people?",
            "If TVs are so thin, why are they impossible to move?",
            "Why does everyone fall asleep watching them but refuse to turn them off?",
            "Why can't the TV just know when I want to watch something?",
            "Why are there so many buttons on the remote for a 'smart' TV?",
            "If it's 4K, why does it still look worse than what I see in person?",
            "Why does my TV need to connect to the internet to show me a picture?",
            "Why does it take five minutes to turn on if it's so smart?"
        ],
        "Coffee": [
            "Why does burnt water cost $6?",
            "Why do people act addicted if it's just a drink?",
            "If coffee is so good, why do people need so much of it?",
            "Why does it taste nothing like it smells?",
            "Why do people claim they can't function without it?",
            "Why is pouring hot water over beans considered fancy?",
            "Why does it ruin your teeth but everyone keeps drinking it?",
            "If it's just beans and water, why does it matter so much?",
            "Why do coffee people take their coffee taste more seriously than actual hobbies?",
            "Why is an iced drink served in a cup more expensive?"
        ],
        "Smartphones": [
            "Why do phones break if you drop them one inch?",
            "Why can't the battery last a full day?",
            "If it's so smart, why does it glitch constantly?",
            "Why is a phone charger $80?",
            "Why do I need a new phone every two years?",
            "Why does every app ask for my location?",
            "If it's waterproof, why can't I use it in the shower?",
            "Why do phone cameras take worse pictures than they look on the screen?",
            "Why does my phone know I'm thinking about something I never searched for?",
            "Why does my phone need a password if I can unlock it with my face?"
        ],
        "Fitness": [
            "Why do people pay to sweat indoors?",
            "If it's healthy, why does it hurt so much?",
            "Why do mirrors exist in gyms if everyone looks bad in them?",
            "Why does the gym play music that nobody wants to hear?",
            "If running is free, why does a treadmill exist?",
            "Why do people show off in the gym if nobody cares?",
            "Why do weights have so many different shapes?",
            "If lifting is so good, why can't you lift the same weight forever?",
            "Why do people go to the gym to not use the equipment?",
            "Why is being sore a badge of honor?"
        ],
        "Dating": [
            "Why is everyone on the same app looking for different things?",
            "Why do people lie about their height by three inches?",
            "If you met online, why pretend you didn't?",
            "Why does everyone say they want something serious on a dating app?",
            "Why are there so many people if dating is hard?",
            "Why do the pictures never match the person?",
            "Why do people ghost instead of just saying no?",
            "If dating apps work, why is everyone still single?",
            "Why do bios say 'no drama' like drama is optional?",
            "Why is swiping considerd romantic?"
        ]
    ]
    
    private let randomTopics = [
        "Grocery Stores",
        "Traffic",
        "Restaurants",
        "Airplanes",
        "Hotels",
        "Weddings",
        "Holidays",
        "Schools",
        "Doctors",
        "Social Media",
        "Streaming Services",
        "WiFi",
        "Passwords",
        "Customer Service",
        "Parking",
        "Meetings",
        "Work Emails",
        "Dishwashers",
        "Thermostats",
        "Pets"
    ]
    
    // Generate a random outsider question for a given topic
    func generateOutsiderQuestions(forTopic topic: String, count: Int = 5) -> [String] {
        let cleanTopic = topic.trimmingCharacters(in: .whitespaces)
        
        if let questions = outsiderQuestionsByTopic[cleanTopic] {
            return Array(questions.shuffled().prefix(count))
        }
        
        // Fallback: generate generic naive questions if topic not found
        return generateGenericOutsiderQuestions(forTopic: cleanTopic, count: count)
    }
    
    // Generate a random topic
    func generateRandomTopic() -> String {
        randomTopics.randomElement() ?? "Life"
    }
    
    // Generate generic outsider questions for unknown topics
    private func generateGenericOutsiderQuestions(forTopic topic: String, count: Int) -> [String] {
        let templates = [
            "Why do people care so much about {topic}?",
            "Why is {topic} so complicated?",
            "Why can't {topic} just be simple?",
            "If {topic} is so great, why does everyone complain about it?",
            "Why do {topic} people take it so seriously?",
            "Why does nobody explain {topic} correctly?",
            "Why do I have to pay for good {topic}?",
            "Why does {topic} always break when I need it?",
            "Why do there need to be so many types of {topic}?",
            "If {topic} is free, why does it feel like you're paying for it?"
        ]
        
        return Array(templates.prefix(count)).map { $0.replacingOccurrences(of: "{topic}", with: topic) }
    }
    
    // Get all available topics (pre-defined + generate)
    func getAllAvailableTopics() -> [String] {
        return Array(outsiderQuestionsByTopic.keys).sorted() + randomTopics
    }
    
    // Check if a topic has pre-generated outsider questions
    func hasPreGeneratedQuestions(forTopic topic: String) -> Bool {
        return outsiderQuestionsByTopic[topic] != nil
    }
}
