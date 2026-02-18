//
//  ContentView.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/2/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showLaunchScreen = true
    
    var body: some View {
        ZStack {
            if showLaunchScreen {
                LaunchScreenView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showLaunchScreen = false
                }
            }
        }
    }
}

enum AppScreen: String, CaseIterable {
    case notepad = "Notepad"
    case jokes = "Jokes"
    case sets = "Set Lists"
    case recordings = "Recordings"
    case notebookSaver = "Notebook Saver"
    
    var icon: String {
        switch self {
        case .notepad: return "note.text"
        case .jokes: return "text.bubble.fill"
        case .sets: return "list.bullet.clipboard.fill"
        case .recordings: return "mic.fill"
        case .notebookSaver: return "book.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .notepad: return .blue
        case .jokes: return .orange
        case .sets: return .purple
        case .recordings: return .red
        case .notebookSaver: return .brown
        }
    }
}

struct MainTabView: View {
    @State private var selectedScreen: AppScreen = .notepad
    @State private var showMenu = false
    
    var body: some View {
        ZStack {
            // Main content
            Group {
                switch selectedScreen {
                case .notepad:
                    HomeView()
                case .jokes:
                    JokesView()
                case .sets:
                    SetListsView()
                case .recordings:
                    RecordingsView()
                case .notebookSaver:
                    NotebookView()
                }
            }
            
            // Dim overlay when menu is open
            if showMenu {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showMenu = false
                        }
                    }
                    .transition(.opacity)
            }
            
            // Side notebook menu & tab
            HStack(spacing: 0) {
                Spacer()
                
                // Menu panel
                if showMenu {
                    NotebookMenu(selectedScreen: $selectedScreen, showMenu: $showMenu)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
                
                // Notebook spine button
                NotebookSpineButton(showMenu: $showMenu)
            }
        }
    }
}

// MARK: - Notebook Spine Button
struct NotebookSpineButton: View {
    @Binding var showMenu: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showMenu.toggle()
                }
            } label: {
                ZStack {
                    // Notebook spine with rings detail
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.55, green: 0.35, blue: 0.22),
                                    Color(red: 0.45, green: 0.28, blue: 0.18)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 40, height: 140)
                        .overlay(
                            // Spine rings
                            VStack(spacing: 18) {
                                ForEach(0..<5) { _ in
                                    Capsule()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 28, height: 4)
                                }
                            }
                        )
                        .shadow(color: .black.opacity(0.25), radius: 6, x: -3, y: 3)
                    
                    // Icon and label
                    VStack(spacing: 6) {
                        Image(systemName: showMenu ? "xmark" : "book.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.95))
                            .rotationEffect(.degrees(showMenu ? 90 : 0))
                        
                        if !showMenu {
                            Text("Menu")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
            }
            .offset(x: showMenu ? 0 : 18)
            
            Spacer()
        }
    }
}

// MARK: - Notebook Menu
struct NotebookMenu: View {
    @Binding var selectedScreen: AppScreen
    @Binding var showMenu: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with notebook look
            HStack(spacing: 10) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("BitBinder")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.08), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            Divider()
                .padding(.horizontal, 16)
            
            // Menu items
            ScrollView(showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(AppScreen.allCases, id: \.self) { screen in
                        NotebookMenuItem(
                            screen: screen,
                            isSelected: selectedScreen == screen
                        ) {
                            selectedScreen = screen
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showMenu = false
                            }
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
            }
            
            Spacer()
            
            // Footer
            HStack {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text("Your comedy companion")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.bottom, 16)
        }
        .frame(width: 240)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, x: -8, y: 0)
        )
        .padding(.trailing, 2)
    }
}

// MARK: - Menu Item
struct NotebookMenuItem: View {
    let screen: AppScreen
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon with colored background
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(screen.color.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: screen.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? screen.color : .secondary)
                }
                
                Text(screen.rawValue)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(screen.color)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? screen.color.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Joke.self, inMemory: true)
}
