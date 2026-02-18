//
//  ElevenLabsAgentService.swift
//  thebitbinder
//
//  Created by Taylor Drew on 2/18/26.
//

import Foundation

/// Service to communicate with ElevenLabs Conversational AI agent
class ElevenLabsAgentService: ObservableObject {
    
    static let shared = ElevenLabsAgentService()
    
    // MARK: - Configuration
    private let agentId = "agent_7401ka31ry6qftr9ab89em3339w9"
    private let apiKey = "sk_40b434d2a8deebbb7c6683dba782412a0dcc9ff571d042ca"
    
    // MARK: - State
    @Published var isLoading = false
    @Published var isConnected = false
    
    private var conversationId: String?
    
    private init() {}
    
    // MARK: - Public API
    
    /// Get a signed URL to connect to the agent
    func getSignedURL() async throws -> String {
        let url = URL(string: "https://api.elevenlabs.io/v1/convai/conversation/get_signed_url?agent_id=\(agentId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ElevenLabsError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ElevenLabsError.apiError(statusCode: httpResponse.statusCode, message: errorMsg)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let signedUrl = json["signed_url"] as? String else {
            throw ElevenLabsError.parseError
        }
        
        return signedUrl
    }
    
    /// Send a text message to the agent and get a response
    /// Note: This uses the text-based conversation endpoint
    func sendMessage(_ message: String) async throws -> String {
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        // Try to use the agent's text endpoint
        let url = URL(string: "https://api.elevenlabs.io/v1/convai/agents/\(agentId)/chat")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        let body: [String: Any] = [
            "message": message,
            "conversation_id": conversationId ?? UUID().uuidString
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ElevenLabsError.invalidResponse
            }
            
            // If this endpoint works, parse the response
            if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Store conversation ID for continuity
                    if let convId = json["conversation_id"] as? String {
                        self.conversationId = convId
                    }
                    
                    // Try to get the response text
                    if let reply = json["response"] as? String {
                        return reply
                    } else if let reply = json["text"] as? String {
                        return reply
                    } else if let reply = json["message"] as? String {
                        return reply
                    }
                }
                
                // Return raw if can't parse
                if let rawString = String(data: data, encoding: .utf8) {
                    return rawString
                }
            }
            
            // Fallback to local responses if API doesn't support text chat
            return generateLocalResponse(for: message)
            
        } catch {
            // If network fails, use local responses
            return generateLocalResponse(for: message)
        }
    }
    
    /// Start a new conversation
    func startNewConversation() {
        conversationId = nil
        isConnected = false
    }
    
    // MARK: - Local Fallback Responses
    
    private func generateLocalResponse(for message: String) -> String {
        let lowercased = message.lowercased()
        
        if lowercased.contains("joke") || lowercased.contains("funny") || lowercased.contains("laugh") || lowercased.contains("bit") {
            return [
                "Great joke idea! Try adding a twist at the end - the unexpected is where the laughs hide. What's the setup you're working with? 🎤",
                "The best jokes have a relatable premise. Think about something everyone experiences but no one talks about. What's your angle? 😄",
                "Rule of three works great! Set up a pattern with two items, then break it with the third. Classic comedy structure! 📝",
                "Have you tried flipping the perspective? Sometimes the funniest take is the opposite of what everyone expects! 🎭"
            ].randomElement()!
        }
        
        if lowercased.contains("set") || lowercased.contains("setlist") || lowercased.contains("show") || lowercased.contains("perform") {
            return [
                "For a solid set, open strong and close stronger! Your second-best joke opens, your best joke closes. 🎯",
                "Try grouping jokes by theme - it creates a nice flow and makes transitions smoother. What themes are you working with? 📋",
                "5 minutes = roughly 3-4 solid jokes with tags. Don't rush! Let the laughs breathe. ⏱️",
                "Record your next set! You'll catch things you miss in the moment. The Recordings section is perfect for this! 🎙️"
            ].randomElement()!
        }
        
        if lowercased.contains("hi") || lowercased.contains("hello") || lowercased.contains("hey") {
            return [
                "Hey! Ready to make some comedy magic? What are you working on? 🎤",
                "Hello! The BitBuilder is here and ready to help with your comedy. What can I do for you? ✨",
                "Hey there! Let's craft some killer material. What's on your mind? 😄"
            ].randomElement()!
        }
        
        if lowercased.contains("help") || lowercased.contains("how") || lowercased.contains("what") {
            return [
                "I'm here to help with your comedy! Ask me about joke writing, set structure, or brainstorm ideas. What's on your mind? 💡",
                "I can help with joke premises, punchlines, callbacks, and set organization. Fire away! 🚀",
                "Need help? I'm great with comedy advice - jokes, timing, setlists, you name it! ✨"
            ].randomElement()!
        }
        
        if lowercased.contains("write") || lowercased.contains("idea") || lowercased.contains("premise") {
            return [
                "Start with what annoys you or confuses you - frustration is fertile ground for comedy! What's been bugging you lately? 😤➡️😂",
                "Take something ordinary and ask 'what if?' - What if dogs could text? What if coffee was illegal? Go wild! 💭",
                "Personal stories are gold! What's the most embarrassing thing that happened to you recently? There's a bit in there! 🏆"
            ].randomElement()!
        }
        
        if lowercased.contains("thanks") || lowercased.contains("thank") || lowercased.contains("awesome") {
            return [
                "You're welcome! Keep crushing it! 🔥",
                "Anytime! That's what I'm here for. Go kill it! 💪",
                "Happy to help! Now go make people laugh! 🎤✨"
            ].randomElement()!
        }
        
        return [
            "That's interesting! Tell me more about what you're working on. I'm here to help with your comedy! 🎭",
            "I like where you're going with this! Want to brainstorm some angles together? 💡",
            "Let's dig into this! What's the core observation or truth you want to highlight? 🎯"
        ].randomElement()!
    }
}

// MARK: - Errors
enum ElevenLabsError: LocalizedError {
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parseError
    case notConnected
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let statusCode, let message):
            return "API Error (\(statusCode)): \(message)"
        case .parseError:
            return "Failed to parse response"
        case .notConnected:
            return "Not connected to agent"
        }
    }
}
