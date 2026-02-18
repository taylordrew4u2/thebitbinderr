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
    case sets = "Sets"
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
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showMenu = false
                        }
                    }
            }
            
            // Side notebook menu
            HStack {
                Spacer()
                
                if showMenu {
                    NotebookMenu(selectedScreen: $selectedScreen, showMenu: $showMenu)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
                
                // Notebook tab button on the right edge
                VStack {
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showMenu.toggle()
                        }
                    } label: {
                        ZStack {
                            // Notebook spine look
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.brown.opacity(0.8), Color.brown.opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 44, height: 120)
                                .shadow(color: .black.opacity(0.3), radius: 4, x: -2, y: 2)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                
                                Text("Menu")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .offset(x: showMenu ? 0 : 22)
                    
                    Spacer()
                }
            }
        }
    }
}

struct NotebookMenu: View {
    @Binding var selectedScreen: AppScreen
    @Binding var showMenu: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Notebook header
            HStack {
                Text("📓 Menu")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding()
            .background(Color.brown.opacity(0.2))
            
            // Menu items
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(AppScreen.allCases, id: \.self) { screen in
                        NotebookMenuItem(
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
                .padding(.vertical, 8)
            }
        }
        .frame(width: 220)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 10, x: -5, y: 0)
        )
        .padding(.trailing, 44)
    }
}

struct NotebookMenuItem: View {
    let screen: AppScreen
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: screen.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .blue : .primary)
                    .frame(width: 24)
                
                Text(screen.rawValue)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .blue : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
            .padding(.horizontal, 8)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Joke.self, inMemory: true)
}
