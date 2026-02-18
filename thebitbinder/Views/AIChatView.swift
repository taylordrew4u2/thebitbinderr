//
//  AIChatView.swift
//  thebitbinder
//
//  Created by Taylor Drew on 2/18/26.
//

import SwiftUI

/// A single message in the AI chat conversation
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(content: String, isUser: Bool) {
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
    }
}

/// Conversational AI chat view powered by ElevenLabs agent
struct AIChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var agentService = ElevenLabsAgentService.shared
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isWaitingForResponse = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle paper background
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.96, blue: 0.93),
                        Color(UIColor.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Chat messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // Welcome message
                                if messages.isEmpty {
                                    WelcomeMessageView()
                                        .padding(.top, 40)
                                }
                                
                                ForEach(messages) { message in
                                    ChatBubbleView(message: message)
                                        .id(message.id)
                                }
                                
                                // Typing indicator
                                if isWaitingForResponse {
                                    TypingIndicatorView()
                                        .id("typing")
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                        .onChange(of: messages.count) {
                            withAnimation {
                                if let lastMessage = messages.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: isWaitingForResponse) {
                            if isWaitingForResponse {
                                withAnimation {
                                    proxy.scrollTo("typing", anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Input area
                    VStack(spacing: 0) {
                        Divider()
                        
                        HStack(spacing: 12) {
                            TextField("Ask me anything...", text: $inputText, axis: .vertical)
                                .textFieldStyle(.plain)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(Color(UIColor.secondarySystemBackground))
                                )
                                .lineLimit(1...5)
                                .focused($isInputFocused)
                                .submitLabel(.send)
                                .onSubmit {
                                    sendMessage()
                                }
                            
                            Button {
                                sendMessage()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(
                                            inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isWaitingForResponse
                                            ? AnyShapeStyle(Color.gray.opacity(0.3))
                                            : AnyShapeStyle(
                                                LinearGradient(
                                                    colors: [.blue, .indigo],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                        )
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isWaitingForResponse)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                    }
                }
            }
            .navigationTitle("The BitBuilder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.secondary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        startNewChat()
                    } label: {
                        Image(systemName: "plus.message")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(content: trimmedText, isUser: true)
        messages.append(userMessage)
        inputText = ""
        isInputFocused = false
        
        // Send to agent
        isWaitingForResponse = true
        
        Task {
            do {
                let reply = try await agentService.sendMessage(trimmedText)
                
                await MainActor.run {
                    let aiMessage = ChatMessage(content: reply, isUser: false)
                    messages.append(aiMessage)
                    isWaitingForResponse = false
                }
            } catch {
                await MainActor.run {
                    isWaitingForResponse = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func startNewChat() {
        messages = []
        agentService.startNewConversation()
    }
}

// MARK: - Supporting Views

struct WelcomeMessageView: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.12), Color.indigo.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("The BitBuilder")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                
                Text("Ask me anything about comedy, jokes, or get help with your sets!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 50) }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.isUser
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [.blue, .indigo.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        : AnyShapeStyle(Color(UIColor.secondarySystemBackground))
                    )
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(18)
                    .shadow(color: message.isUser ? .blue.opacity(0.15) : .clear, radius: 4, y: 2)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            if !message.isUser { Spacer(minLength: 50) }
        }
    }
}

struct TypingIndicatorView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack {
            HStack(spacing: 5) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .offset(y: isAnimating ? -5 : 0)
                        .animation(
                            Animation.easeInOut(duration: 0.4)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                            value: isAnimating
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(18)
            
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    AIChatView()
}
