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
    @Published var lastError: String?
    
    /// Current conversation ID for continuity
    private var conversationId: String?
    
    private init() {}
    
    // MARK: - Public API
    
    /// Send a message to the ElevenLabs agent
    func sendMessage(_ message: String) async throws -> String {
        await MainActor.run {
            isLoading = true
            lastError = nil
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        // If no conversation, start one first
        if conversationId == nil {
            try await startConversation()
        }
        
        // Send the message
        return try await sendToAgent(message)
    }
    
    /// Start a new conversation
    func startNewConversation() {
        conversationId = nil
    }
    
    // MARK: - Private Methods
    
    private func startConversation() async throws {
        let url = URL(string: "https://api.elevenlabs.io/v1/convai/conversations")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "agent_id": agentId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AgentError.noResponse
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AgentError.serverError(httpResponse.statusCode, errorMsg)
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let convId = json["conversation_id"] as? String {
            self.conversationId = convId
        }
    }
    
    private func sendToAgent(_ message: String) async throws -> String {
        guard let convId = conversationId else {
            throw AgentError.noConversation
        }
        
        let url = URL(string: "https://api.elevenlabs.io/v1/convai/conversations/\(convId)/messages")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        let body: [String: Any] = [
            "text": message
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AgentError.noResponse
        }
        
        // If conversation expired, start fresh and retry
        if httpResponse.statusCode == 404 {
            conversationId = nil
            try await startConversation()
            return try await sendToAgent(message)
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AgentError.serverError(httpResponse.statusCode, errorMsg)
        }
        
        // Parse response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // Try different possible response fields
            if let reply = json["text"] as? String {
                return reply
            } else if let reply = json["response"] as? String {
                return reply
            } else if let reply = json["message"] as? String {
                return reply
            } else if let messages = json["messages"] as? [[String: Any]],
                      let lastMessage = messages.last,
                      let text = lastMessage["text"] as? String {
                return text
            }
        }
        
        // Return raw response if can't parse
        if let rawString = String(data: data, encoding: .utf8), !rawString.isEmpty {
            return rawString
        }
        
        throw AgentError.noResponse
    }
}

// MARK: - Errors
enum AgentError: LocalizedError {
    case noResponse
    case noConversation
    case serverError(Int, String)
    
    var errorDescription: String? {
        switch self {
        case .noResponse:
            return "No response from AI assistant"
        case .noConversation:
            return "No active conversation"
        case .serverError(let code, let message):
            return "Error (\(code)): \(message)"
        }
    }
}
