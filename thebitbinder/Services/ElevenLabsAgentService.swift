//
//  ElevenLabsAgentService.swift
//  thebitbinder
//
//  Created by Taylor Drew on 2/18/26.
//

import Foundation

/// Response from the ElevenLabs agent proxy
struct AgentResponse: Codable {
    let reply: String
    let sessionId: String?
    
    enum CodingKeys: String, CodingKey {
        case reply
        case sessionId = "session_id"
    }
}

/// Error types for ElevenLabs agent communication
enum ElevenLabsAgentError: LocalizedError {
    case invalidURL
    case networkError(String)
    case serverError(Int, String)
    case decodingError(String)
    case noResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL configuration"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .noResponse:
            return "No response from server"
        }
    }
}

/// Service to communicate with ElevenLabs Conversational AI agent via backend proxy
/// Agent ID: agent_7401ka31ry6qftr9ab89em3339w9
class ElevenLabsAgentService: ObservableObject {
    
    static let shared = ElevenLabsAgentService()
    
    // MARK: - Configuration
    
    /// Backend proxy URL - CONFIGURE THIS to your deployed backend
    /// Example: "https://your-backend.com/api/elevenlabs"
    private let backendBaseURL: String = "https://your-backend-url.com/api/agent"
    
    /// The ElevenLabs agent ID (used by backend, not sent from client for security)
    /// This is just for reference - the backend should have this configured
    static let agentId = "agent_7401ka31ry6qftr9ab89em3339w9"
    
    // MARK: - State
    
    @Published var isLoading = false
    @Published var lastError: String?
    
    /// Current session ID for conversation continuity
    private var sessionId: String?
    
    private init() {}
    
    // MARK: - Public API
    
    /// Send a message to the ElevenLabs agent
    /// - Parameter message: User's message text
    /// - Returns: The agent's reply
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
        
        guard let url = URL(string: "\(backendBaseURL)/chat") else {
            throw ElevenLabsAgentError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60 // Agents can take time to respond
        
        // Build request body - include access code, message, and optional session
        var body: [String: Any] = [
            "message": message,
            "access_code": "9856"  // Always include access code for authentication
        ]
        if let sessionId = sessionId {
            body["session_id"] = sessionId
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ElevenLabsAgentError.noResponse
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw ElevenLabsAgentError.serverError(httpResponse.statusCode, errorMessage)
            }
            
            let agentResponse = try JSONDecoder().decode(AgentResponse.self, from: data)
            
            // Store session ID for conversation continuity
            if let newSessionId = agentResponse.sessionId {
                self.sessionId = newSessionId
            }
            
            return agentResponse.reply
            
        } catch let error as ElevenLabsAgentError {
            await MainActor.run {
                lastError = error.localizedDescription
            }
            throw error
        } catch let error as DecodingError {
            let decodingError = ElevenLabsAgentError.decodingError(error.localizedDescription)
            await MainActor.run {
                lastError = decodingError.localizedDescription
            }
            throw decodingError
        } catch {
            let networkError = ElevenLabsAgentError.networkError(error.localizedDescription)
            await MainActor.run {
                lastError = networkError.localizedDescription
            }
            throw networkError
        }
    }
    
    /// Start a new conversation (clears session)
    func startNewConversation() {
        sessionId = nil
    }
    
    /// Check if there's an active conversation session
    var hasActiveSession: Bool {
        sessionId != nil
    }
}

// MARK: - Backend Proxy Example
/*
 Your backend proxy should handle:
 
 1. Receive iOS request:
    POST /api/agent/chat
    {
      "message": "User text",
      "session_id": "optional"
    }
 
 2. Forward to ElevenLabs:
    POST https://api.elevenlabs.io/v1/convai/agents/{agent_id}/chat
    Headers:
      - xi-api-key: YOUR_SECRET_KEY
    Body:
      - message, session_id, etc.
 
 3. Handle tool calls if required by the agent
 
 4. Return clean response to iOS:
    {
      "reply": "Agent's response text",
      "session_id": "conversation_session_id"
    }
 
 Example Node.js/Express backend:
 
 ```javascript
 const express = require('express');
 const axios = require('axios');
 
 const ELEVENLABS_API_KEY = process.env.ELEVENLABS_API_KEY;
 const AGENT_ID = 'agent_7401ka31ry6qftr9ab89em3339w9';
 
 app.post('/api/agent/chat', async (req, res) => {
   try {
     const { message, session_id } = req.body;
     
     const response = await axios.post(
       `https://api.elevenlabs.io/v1/convai/agents/${AGENT_ID}/chat`,
       {
         message,
         session_id
       },
       {
         headers: {
           'xi-api-key': ELEVENLABS_API_KEY,
           'Content-Type': 'application/json'
         }
       }
     );
     
     res.json({
       reply: response.data.response || response.data.text,
       session_id: response.data.session_id
     });
   } catch (error) {
     console.error('Agent error:', error.response?.data || error.message);
     res.status(500).json({ error: 'Agent request failed' });
   }
 });
 ```
*/
