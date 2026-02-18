//
//  AIChatView.swift
//  thebitbinder
//
//  Created by Taylor Drew on 2/18/26.
//

import SwiftUI

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

struct AIChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var agentService = ElevenLabsAgentService.shared
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isWaitingForResponse = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @FocusState private var isInputFocused: Bool
    
    private let gradientColors = [Color(red: 0.4, green: 0.3, blue: 1.0), Color(red: 0.6, green: 0.2, blue: 0.9)]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color(UIColor.systemBackground),
                        Color(UIColor.secondarySystemBackground).opacity(0.5)
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
                                if messages.isEmpty {
                                    BitBuilderWelcomeView(gradientColors: gradientColors)
                                        .padding(.top, 60)
                                }
                                
                                ForEach(messages) { message in
                                    BitBuilderChatBubble(message: message, gradientColors: gradientColors)
                                        .id(message.id)
                                }
                                
                                if isWaitingForResponse {
                                    BitBuilderTypingIndicator()
                                        .id("typing")
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                        }
                        .onChange(of: messages.count) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                if let lastMessage = messages.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: isWaitingForResponse) {
                            if isWaitingForResponse {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo("typing", anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Input area
                    BitBuilderInputBar(
                        inputText: $inputText,
                        isInputFocused: _isInputFocused,
                        isWaitingForResponse: isWaitingForResponse,
                        gradientColors: gradientColors,
                        sendAction: sendMessage
                    )
                }
            }
            .navigationTitle("The BitBuilder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color(UIColor.tertiarySystemFill)))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        messages = []
                        agentService.startNewConversation()
                    } label: {
                        Image(systemName: "plus.bubble")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(gradientColors[0])
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
        messages.append(ChatMessage(content: trimmedText, isUser: true))
        inputText = ""
        isInputFocused = false
        isWaitingForResponse = true
        
        // Send to ElevenLabs agent
        Task {
            do {
                let response = try await agentService.sendMessage(trimmedText)
                
                await MainActor.run {
                    messages.append(ChatMessage(content: response, isUser: false))
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
}

// MARK: - Welcome View
struct BitBuilderWelcomeView: View {
    let gradientColors: [Color]
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [gradientColors[0].opacity(0.2), gradientColors[1].opacity(0.05)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 70
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            
            VStack(spacing: 10) {
                Text("The BitBuilder")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                
                Text("Your AI comedy assistant.\nPowered by ElevenLabs")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Chat Bubble
struct BitBuilderChatBubble: View {
    let message: ChatMessage
    let gradientColors: [Color]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser { Spacer(minLength: 40) }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        message.isUser
                        ? AnyShapeStyle(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(Color(UIColor.secondarySystemBackground))
                    )
                    .foregroundColor(message.isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: message.isUser ? gradientColors[0].opacity(0.2) : .clear, radius: 6, y: 3)
                
                Text(message.timestamp, style: .time)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
            }
            
            if !message.isUser { Spacer(minLength: 40) }
        }
    }
}

// MARK: - Input Bar
struct BitBuilderInputBar: View {
    @Binding var inputText: String
    @FocusState var isInputFocused: Bool
    let isWaitingForResponse: Bool
    let gradientColors: [Color]
    let sendAction: () -> Void
    
    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isWaitingForResponse
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(alignment: .bottom, spacing: 12) {
                TextField("Message The BitBuilder...", text: $inputText, axis: .vertical)
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit(sendAction)
                
                Button(action: sendAction) {
                    ZStack {
                        Circle()
                            .fill(
                                canSend
                                ? LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
    }
}

// MARK: - Typing Indicator
struct BitBuilderTypingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.secondary.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .offset(y: isAnimating ? -6 : 0)
                        .animation(
                            Animation.easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.12),
                            value: isAnimating
                        )
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            
            Spacer()
        }
        .onAppear { isAnimating = true }
    }
}

#Preview {
    AIChatView()
}
