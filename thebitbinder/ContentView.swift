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
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(0)
                .tabItem {
                    Label("Notepad", systemImage: "note.text")
                }
            
            JokesView()
                .tag(1)
                .tabItem {
                    Label("Jokes", systemImage: "text.bubble.fill")
                }
            
            SetListsView()
                .tag(2)
                .tabItem {
                    Label("Sets", systemImage: "list.bullet.clipboard.fill")
                }
            
            RecordingsView()
                .tag(3)
                .tabItem {
                    Label("Record", systemImage: "mic.fill")
                }
            
            NotebookView()
                .tag(4)
                .tabItem {
                    Label("Photos", systemImage: "photo.fill")
                }
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Joke.self, inMemory: true)
}
