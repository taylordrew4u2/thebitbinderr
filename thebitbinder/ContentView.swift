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

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Notepad", systemImage: "note.text")
                }
            
            JokesView()
                .tabItem {
                    Label("Jokes", systemImage: "text.bubble.fill")
                }
            
            SetListsView()
                .tabItem {
                    Label("Sets", systemImage: "list.bullet.clipboard.fill")
                }
            
            RecordingsView()
                .tabItem {
                    Label("Recordings", systemImage: "mic.fill")
                }
            
            GymView()
                .tabItem {
                    Label("Gym", systemImage: "dumbbell.fill")
                }
            
            NotebookView()
                .tabItem {
                    Label("Notebook Saver", systemImage: "book.fill")
                }
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Joke.self, inMemory: true)
}