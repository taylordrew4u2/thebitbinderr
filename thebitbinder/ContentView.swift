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
        ZStack(alignment: .trailing) {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Dim overlay when menu is open
            if showMenu {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showMenu = false
                        }
                    }
            }
            
            // Side menu panel (slides in from right)
            if showMenu {
                SideMenuView(selectedScreen: $selectedScreen, showMenu: $showMenu)
                    .transition(.move(edge: .trailing))
            }
            
            // Menu toggle button (always visible on right edge)
            if !showMenu {
                VStack {
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showMenu = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Menu")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.indigo],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                        )
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 100)
                }
            }
        }
    }
}

// MARK: - Side Menu View
struct SideMenuView: View {
    @Binding var selectedScreen: AppScreen
    @Binding var showMenu: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("BitBinder")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                    
                    Text("Your comedy companion")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showMenu = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
            .background(Color(UIColor.secondarySystemBackground).opacity(0.5))
            
            // Menu items
            VStack(spacing: 4) {
                ForEach(AppScreen.allCases, id: \.self) { screen in
                    MenuItemButton(
                        screen: screen,
                        isSelected: selectedScreen == screen
                    ) {
                        selectedScreen = screen
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showMenu = false
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            
            Spacer()
            
            // Version footer
            Text("v1.0")
                .font(.caption2)
                .foregroundStyle(.quaternary)
                .padding(.bottom, 20)
        }
        .frame(width: 280)
        .frame(maxHeight: .infinity)
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: .black.opacity(0.2), radius: 20, x: -10, y: 0)
        )
        .ignoresSafeArea()
    }
}

// MARK: - Menu Item Button
struct MenuItemButton: View {
    let screen: AppScreen
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(screen.color.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: screen.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? screen.color : .secondary)
                }
                
                // Label
                Text(screen.rawValue)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Circle()
                        .fill(screen.color)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? screen.color.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Joke.self, inMemory: true)
}
