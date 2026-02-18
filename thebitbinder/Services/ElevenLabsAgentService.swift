//
//  ElevenLabsAgentService.swift
//  thebitbinder
//
//  Created by Taylor Drew on 2/18/26.
//

import Foundation

/// Service for interacting with ElevenLabs Conversational AI Agent
class ElevenLabsAgentService: ObservableObject {
    static let shared = ElevenLabsAgentService()
    
    private let agentId = "agent_7401ka31ry6qftr9ab89em3339w9"
    private let apiKey = "sk_40b434d2a8deebbb7c6683dba782412a0dcc9ff571d042ca"
    private let baseURL = "https://api.elevenlabs.io/v1/convai"
    
    @Published var isConnected = false
    @Published var conversationId: String?
    
    private init() {}
    
    /// Start a new conversation with the agent
    func startConversation() async throws -> String {
        let url = URL(string: "\(baseURL)/conversation/\(agentId)/start")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{}".data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AgentError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AgentError.apiError(statusCode: httpResponse.statusCode)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if let convId = json?["conversation_id"] as? String {
            await MainActor.run {
                self.conversationId = convId
                self.isConnected = true
            }
            return convId
        }
        
        throw AgentError.noConversationId
    }
    
    /// Send a message to the agent and get a response
    func sendMessage(_ message: String) async throws -> String {
        // Start conversation if not already started
        let convId: String
        if let existingId = conversationId {
            convId = existingId
        } else {
            convId = try await startConversation()
        }
        
        let url = URL(string: "\(baseURL)/conversation/\(convId)/message")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "message": message,
            "access_code": "9856"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AgentError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // If conversation expired, start a new one and retry
            if httpResponse.statusCode == 404 || httpResponse.statusCode == 400 {
                await MainActor.run {
                    self.conversationId = nil
                    self.isConnected = false
                }
                // Retry with new conversation
                _ = try await startConversation()
                return try await sendMessage(message)
            }
            throw AgentError.apiError(statusCode: httpResponse.statusCode)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if let reply = json?["response"] as? String {
            return reply
        } else if let reply = json?["message"] as? String {
            return reply
        } else if let reply = json?["text"] as? String {
            return reply
        }
        
        // Return raw JSON if we can't parse specific field
        if let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        
        throw AgentError.noResponse
    }
    
    /// End the current conversation
    func endConversation() {
        conversationId = nil
        isConnected = false
    }
    
    /// Start a fresh conversation
    func startNewConversation() {
        endConversation()
    }
}

// MARK: - Errors
enum AgentError: LocalizedError {
    case invalidResponse
    case apiError(statusCode: Int)
    case noConversationId
    case noResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let statusCode):
            return "API error (status \(statusCode))"
        case .noConversationId:
            return "Failed to get conversation ID"
        case .noResponse:
            return "No response from agent"
        }
    }
}
