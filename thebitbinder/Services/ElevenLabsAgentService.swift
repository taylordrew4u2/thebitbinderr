//
//  ElevenLabsAgentService.swift
//  thebitbinder
//
//  Created by Taylor Drew on 2/18/26.
//

import Foundation
import AVFoundation

/// Service to communicate with ElevenLabs Conversational AI agent
/// Agent ID: agent_7401ka31ry6qftr9ab89em3339w9
class ElevenLabsAgentService: NSObject, ObservableObject {
    
    static let shared = ElevenLabsAgentService()
    
    // MARK: - Configuration
    private let agentId = "agent_7401ka31ry6qftr9ab89em3339w9"
    private let apiKey = "sk_40b434d2a8deebbb7c6683dba782412a0dcc9ff571d042ca"
    
    // MARK: - State
    @Published var isLoading = false
    @Published var isConnected = false
    
    private var conversationId: String?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public API
    
    /// Send a text message and get a response from the agent
    func sendMessage(_ message: String) async throws -> String {
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        // Try to get response from ElevenLabs
        do {
            let response = try await sendToElevenLabs(message)
            return response
        } catch {
            // If API fails, just return "brb"
            print("ElevenLabs API error: \(error.localizedDescription)")
            return "brb"
        }
    }
    
    /// Start a new conversation
    func startNewConversation() {
        conversationId = nil
        isConnected = false
    }
    
    // MARK: - Private Methods
    
    private func sendToElevenLabs(_ message: String) async throws -> String {
        // First get a signed URL to verify connection
        let signedURL = try await getSignedURL()
        print("Got signed URL: \(signedURL)")
        
        await MainActor.run {
            isConnected = true
        }
        
        // Try the conversation endpoint
        let url = URL(string: "https://api.elevenlabs.io/v1/convai/conversation")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        var body: [String: Any] = [
            "agent_id": agentId,
            "text": message
        ]
        
        if let convId = conversationId {
            body["conversation_id"] = convId
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ElevenLabsError.invalidResponse
        }
        
        let responseString = String(data: data, encoding: .utf8) ?? "No data"
        print("ElevenLabs Response (\(httpResponse.statusCode)): \(responseString)")
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Save conversation ID
                if let convId = json["conversation_id"] as? String {
                    self.conversationId = convId
                }
                
                // Extract response text from various possible fields
                if let response = json["response"] as? String {
                    return response
                } else if let response = json["text"] as? String {
                    return response
                } else if let response = json["message"] as? String {
                    return response
                } else if let response = json["agent_response"] as? String {
                    return response
                } else if let response = json["output"] as? String {
                    return response
                }
            }
            
            // Return raw response if can't parse specific field
            if !responseString.isEmpty && responseString != "No data" {
                return responseString
            }
        }
        
        throw ElevenLabsError.apiError(statusCode: httpResponse.statusCode, message: responseString)
    }
    
    private func getSignedURL() async throws -> String {
        let url = URL(string: "https://api.elevenlabs.io/v1/convai/conversation/get_signed_url?agent_id=\(agentId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.timeoutInterval = 15
        
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
