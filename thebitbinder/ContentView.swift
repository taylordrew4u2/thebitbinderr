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
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 1.02)),
                        removal: .opacity
                    ))
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeOut(duration: 0.4)) {
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
    case notebookSaver = "Notebook"
    
    var icon: String {
        switch self {
        case .notepad: return "square.and.pencil"
        case .jokes: return "face.smiling.fill"
        case .sets: return "list.bullet.rectangle.fill"
        case .recordings: return "waveform.circle.fill"
        case .notebookSaver: return "book.closed.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .notepad: return Color(red: 0.3, green: 0.6, blue: 1.0)
        case .jokes: return Color(red: 1.0, green: 0.6, blue: 0.2)
        case .sets: return Color(red: 0.7, green: 0.4, blue: 1.0)
        case .recordings: return Color(red: 1.0, green: 0.35, blue: 0.4)
        case .notebookSaver: return Color(red: 0.6, green: 0.5, blue: 0.4)
        }
    }
}

struct MainTabView: View {
    @State private var selectedScreen: AppScreen = .notepad
    @State private var showMenu = false
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Main content with subtle animation
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Glassmorphic overlay
            if showMenu {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showMenu = false
                        }
                    }
                    .transition(.opacity)
            }
            
            // Modern side menu
            if showMenu {
                ModernSideMenu(selectedScreen: $selectedScreen, showMenu: $showMenu)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
            
            // Floating menu button
            if !showMenu {
                VStack {
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showMenu = true
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 56, height: 56)
                            
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [selectedScreen.color, selectedScreen.color.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 52, height: 52)
                            
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .shadow(color: selectedScreen.color.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Modern Side Menu
struct ModernSideMenu: View {
    @Binding var selectedScreen: AppScreen
    @Binding var showMenu: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showMenu = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color(UIColor.tertiarySystemFill)))
                    }
                }
                
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BitBinder")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text("Your comedy companion")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 8)
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color(UIColor.secondarySystemBackground), Color(UIColor.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Menu items with modern cards
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(AppScreen.allCases, id: \.self) { screen in
                        ModernMenuItem(
                            screen: screen,
                            isSelected: selectedScreen == screen
                        ) {
                            selectedScreen = screen
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                showMenu = false
                            }
                        }
                    }
                }
                .padding(16)
            }
            
            Spacer()
            
            // Footer
            HStack(spacing: 4) {
                Image(systemName: "sparkle")
                    .font(.caption2)
                Text("v1.0")
                    .font(.caption2)
            }
            .foregroundStyle(.quaternary)
            .padding(.bottom, 24)
        }
        .frame(width: 300)
        .frame(maxHeight: .infinity)
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: .black.opacity(0.25), radius: 30, x: -15, y: 0)
        )
        .ignoresSafeArea()
    }
}

// MARK: - Modern Menu Item
struct ModernMenuItem: View {
    let screen: AppScreen
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon with gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            isSelected
                            ? LinearGradient(colors: [screen.color, screen.color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [screen.color.opacity(0.15), screen.color.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: screen.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? .white : screen.color)
                }
                
                // Label
                Text(screen.rawValue)
                    .font(.system(size: 17, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? AnyShapeStyle(screen.color) : AnyShapeStyle(.quaternary))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? screen.color.opacity(0.1) : Color(UIColor.secondarySystemBackground).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? screen.color.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Joke.self, inMemory: true)
}
