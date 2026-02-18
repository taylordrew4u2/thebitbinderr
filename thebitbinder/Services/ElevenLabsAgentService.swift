//
//  ElevenLabsAgentService.swift
//  thebitbinder
//
//  Created by Taylor Drew on 2/18/26.
//

import Foundation
import AVFoundation

/// Service to communicate with ElevenLabs Conversational AI agent via proxy
/// Proxy URL: https://elevenlabs-proxy.taylordrew4u.workers.dev/
/// Agent ID: agent_7401ka31ry6qftr9ab89em3339w9
/// Access Code: 9856
class ElevenLabsAgentService: NSObject, ObservableObject {
    
    static let shared = ElevenLabsAgentService()
    
    // MARK: - Configuration
    private let proxyURL = "https://elevenlabs-proxy.taylordrew4u.workers.dev"
    private let accessCode = "9856"
    
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
        
        // Try to get response from ElevenLabs via proxy
        do {
            let response = try await sendToProxy(message)
            return response
        } catch {
            // If API fails, just return "brb"
            print("ElevenLabs Proxy error: \(error.localizedDescription)")
            return "brb"
        }
    }
    
    /// Start a new conversation
    func startNewConversation() {
        conversationId = nil
        isConnected = false
    }
    
    // MARK: - Private Methods
    
    private func sendToProxy(_ message: String) async throws -> String {
        guard let url = URL(string: proxyURL) else {
            throw ElevenLabsError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        var body: [String: Any] = [
            "message": message,
            "access_code": accessCode
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
        print("ElevenLabs Proxy Response (\(httpResponse.statusCode)): \(responseString)")
        
        if httpResponse.statusCode == 200 {
            await MainActor.run {
                isConnected = true
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Save conversation ID if returned
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
                } else if let response = json["signed_url"] as? String {
                    // If we got a signed URL, the proxy started a conversation
                    // Return a welcome message
                    return "Hey! I'm The BitBuilder, your comedy assistant. How can I help you today? 🎤"
                }
            }
            
            // Return raw response if can't parse specific field
            if !responseString.isEmpty && responseString != "No data" && !responseString.contains("signed_url") {
                return responseString
            }
            
            return "Connected! How can I help with your comedy? 🎭"
        }
        
        throw ElevenLabsError.apiError(statusCode: httpResponse.statusCode, message: responseString)
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
