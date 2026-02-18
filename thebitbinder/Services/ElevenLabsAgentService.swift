//
//  ElevenLabsAgentService.swift
//  thebitbinder
//
//  Created by Taylor Drew on 2/18/26.
//

import Foundation

/// Service to communicate with AI assistant
/// Note: ElevenLabs ConvAI requires WebSocket - using placeholder responses for now
class ElevenLabsAgentService: ObservableObject {
    
    static let shared = ElevenLabsAgentService()
    
    // MARK: - State
    @Published var isLoading = false
    
    private var conversationHistory: [[String: String]] = []
    
    private init() {}
    
    // MARK: - Public API
    
    /// Send a message and get a response
    func sendMessage(_ message: String) async throws -> String {
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        // Add user message to history
        conversationHistory.append(["role": "user", "content": message])
        
        // Brief delay for natural feel
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // Generate contextual response
        let response = generateResponse(for: message)
        conversationHistory.append(["role": "assistant", "content": response])
        
        return response
    }
    
    /// Start a new conversation
    func startNewConversation() {
        conversationHistory = []
    }
    
    // MARK: - Private Methods
    
    private func generateResponse(for message: String) -> String {
        let lowercased = message.lowercased()
        
        // Comedy-specific responses
        if lowercased.contains("joke") || lowercased.contains("funny") || lowercased.contains("laugh") {
            return [
                "Great joke idea! Try adding a twist at the end - the unexpected is where the laughs hide. What's the setup you're working with? 🎤",
                "The best jokes have a relatable premise. Think about something everyone experiences but no one talks about. What's your angle? 😄",
                "Rule of three works great! Set up a pattern with two items, then break it with the third. Classic comedy structure! 📝",
                "Have you tried flipping the perspective? Sometimes the funniest take is the opposite of what everyone expects! 🎭"
            ].randomElement()!
        }
        
        if lowercased.contains("set") || lowercased.contains("setlist") || lowercased.contains("show") {
            return [
                "For a solid set, open strong and close stronger! Your second-best joke opens, your best joke closes. 🎯",
                "Try grouping jokes by theme - it creates a nice flow and makes transitions smoother. What themes are you working with? 📋",
                "5 minutes = roughly 3-4 solid jokes with tags. Don't rush! Let the laughs breathe. ⏱️",
                "Record your next set! You'll catch things you miss in the moment. The Recordings tab is perfect for this! 🎙️"
            ].randomElement()!
        }
        
        if lowercased.contains("help") || lowercased.contains("how") || lowercased.contains("what") {
            return [
                "I'm here to help with your comedy! You can ask me about joke writing, set structure, or brainstorm ideas. What's on your mind? 💡",
                "Need help? Try the Jokes section to organize material, or Recordings to capture your sets. What would you like to work on? ✨",
                "I can help with joke premises, punchlines, callbacks, and set organization. Fire away! 🚀"
            ].randomElement()!
        }
        
        if lowercased.contains("hi") || lowercased.contains("hello") || lowercased.contains("hey") {
            return [
                "Hey! Ready to make some comedy magic? What are you working on? 🎤",
                "Hello, fellow comedy enthusiast! What jokes are we crafting today? ✨",
                "Hey there! Your comedy assistant is here. What can I help you with? 😄"
            ].randomElement()!
        }
        
        if lowercased.contains("write") || lowercased.contains("idea") || lowercased.contains("premise") {
            return [
                "Start with what annoys you or confuses you - frustration is fertile ground for comedy! What's been bugging you lately? 😤➡️😂",
                "Take something ordinary and ask 'what if?' - What if dogs could text? What if coffee was illegal? Go wild! 💭",
                "Personal stories are gold! What's the most embarrassing thing that happened to you recently? There's a bit in there! 🏆",
                "Try the 'hard truth' approach - say the thing everyone thinks but won't say out loud. That's where the big laughs live! 💯"
            ].randomElement()!
        }
        
        // Default responses
        return [
            "That's interesting! Tell me more about what you're working on. I'm here to help with your comedy! 🎭",
            "I like where you're going with this! Want to brainstorm some angles together? 💡",
            "Comedy gold is in the details! What else can you tell me about this idea? 📝",
            "Let's dig into this! What's the core observation or truth you want to highlight? 🎯"
        ].randomElement()!
    }
}

// MARK: - Errors
enum AgentError: LocalizedError {
    case noResponse
    
    var errorDescription: String? {
        switch self {
        case .noResponse:
            return "No response from AI assistant"
        }
    }
}
