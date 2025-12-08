//
//  AutoOrganizeView.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/7/25.
//

import SwiftUI
import SwiftData

struct AutoOrganizeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query private var jokes: [Joke]
    @Query private var folders: [JokeFolder]
    
    @State private var categories = AutoOrganizeService.getCategories()
    @State private var newCategory = ""
    @State private var isOrganizing = false
    @State private var showResults = false
    @State private var organizedCount = 0
    @State private var needsReviewCount = 0
    
    var unorganizedJokes: [Joke] {
        jokes.filter { $0.folder == nil }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Actions
                    if !unorganizedJokes.isEmpty {
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(unorganizedJokes.count) jokes need organizing")
                                        .font(.headline)
                                    Text("Let AI help you sort them")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            
                            Button(action: organizeAll) {
                                HStack {
                                    if isOrganizing {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "wand.and.stars")
                                        Text("Auto-Organize All")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isOrganizing)
                            
                            if showResults {
                                VStack(spacing: 8) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("\(organizedCount) organized automatically")
                                            .font(.subheadline)
                                    }
                                    if needsReviewCount > 0 {
                                        HStack {
                                            Image(systemName: "questionmark.circle.fill")
                                                .foregroundColor(.orange)
                                            Text("\(needsReviewCount) need manual review")
                                                .font(.subheadline)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                            Text("All Jokes Organized!")
                                .font(.headline)
                            Text("Great job keeping things tidy")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    
                    // Individual Jokes with Smart Suggestions
                    if !unorganizedJokes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Review & Organize")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(unorganizedJokes) { joke in
                                JokeOrganizeCard(
                                    joke: joke,
                                    categories: categories,
                                    folders: folders,
                                    modelContext: modelContext
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                        .padding(.vertical)
                    
                    // Manage Categories
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Your Categories")
                                .font(.headline)
                            Spacer()
                            Text("\(categories.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            ForEach(categories, id: \.self) { category in
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.blue)
                                    Text(category)
                                        .font(.subheadline)
                                    Spacer()
                                    Button(action: { removeCategory(category) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red.opacity(0.7))
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(8)
                            }
                            
                            HStack {
                                TextField("Add new category", text: $newCategory)
                                    .textFieldStyle(.roundedBorder)
                                
                                Button(action: addCategory) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 24))
                                }
                                .disabled(newCategory.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .padding(.vertical)
            }
            .navigationTitle("Auto-Organize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func organizeAll() {
        isOrganizing = true
        showResults = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let results = AutoOrganizeService.organizeAllJokes(
                unorganizedJokes,
                existingFolders: folders,
                modelContext: modelContext
            )
            
            organizedCount = results.organized
            needsReviewCount = results.needsReview
            isOrganizing = false
            showResults = true
        }
    }
    
    private func addCategory() {
        let trimmed = newCategory.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty && !categories.contains(trimmed) else { return }
        
        categories.append(trimmed)
        AutoOrganizeService.setCategories(categories)
        newCategory = ""
    }
    
    private func removeCategory(_ category: String) {
        categories.removeAll { $0 == category }
        AutoOrganizeService.setCategories(categories)
    }
}

// MARK: - Joke Organize Card

struct JokeOrganizeCard: View {
    let joke: Joke
    let categories: [String]
    let folders: [JokeFolder]
    let modelContext: ModelContext
    
    @State private var suggestions: [(category: String, confidence: Int)] = []
    @State private var showAllCategories = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(joke.title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(joke.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggestions")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    HStack(spacing: 8) {
                        ForEach(suggestions, id: \.category) { suggestion in
                            Button(action: {
                                organizeJoke(into: suggestion.category)
                            }) {
                                HStack(spacing: 4) {
                                    Text(suggestion.category)
                                    if suggestion.confidence >= 3 {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 8))
                                            .foregroundColor(.yellow)
                                    }
                                }
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.15))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                            }
                        }
                    }
                }
            }
            
            HStack {
                Button(action: { showAllCategories.toggle() }) {
                    HStack {
                        Image(systemName: "folder")
                        Text("More...")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .onAppear {
            suggestions = AutoOrganizeService.suggestCategories(for: joke)
        }
        .sheet(isPresented: $showAllCategories) {
            NavigationStack {
                List(categories, id: \.self) { category in
                    Button(action: {
                        organizeJoke(into: category)
                        showAllCategories = false
                    }) {
                        Text(category)
                    }
                }
                .navigationTitle("Choose Category")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            showAllCategories = false
                        }
                    }
                }
            }
        }
    }
    
    private func organizeJoke(into category: String) {
        AutoOrganizeService.organizeJoke(
            joke,
            intoCategory: category,
            existingFolders: folders,
            modelContext: modelContext
        )
    }
}
