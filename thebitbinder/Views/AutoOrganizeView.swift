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
    
    @State private var categories = AutoOrganizeService.getUserCategories()
    @State private var newCategory = ""
    @State private var showAddCategory = false
    @State private var organizationResult: (organized: Int, suggested: Int) = (0, 0)
    @State private var showResult = false
    @State private var selectedForCategory: Joke?
    @State private var showCategoryMenu = false
    
    var unorganizedJokes: [Joke] {
        jokes.filter { $0.folder == nil }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Auto-Organize Jokes")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(unorganizedJokes.count) unorganized jokes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Auto-Organize Button
                        if !unorganizedJokes.isEmpty {
                            Button(action: performAutoOrganize) {
                                HStack(spacing: 12) {
                                    Image(systemName: "wand.and.stars")
                                    Text("Auto-Organize All")
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.blue)
                                .cornerRadius(10)
                            }
                            .padding()
                        }
                        
                        // Unorganized Jokes List
                        if !unorganizedJokes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Select Category for Each Joke")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(unorganizedJokes) { joke in
                                    JokeOrganizeCard(
                                        joke: joke,
                                        onSelectCategory: { category in
                                            joke.folder = folders.first { $0.name == category }
                                            if joke.folder == nil {
                                                let newFolder = JokeFolder(name: category)
                                                modelContext.insert(newFolder)
                                                joke.folder = newFolder
                                            }
                                        }
                                    )
                                }
                            }
                            .padding()
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.green)
                                
                                Text("All Jokes Organized!")
                                    .font(.headline)
                                
                                Text("Great job! All your jokes have been categorized.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Manage Categories Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Manage Categories")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            // Add Category
                            HStack(spacing: 8) {
                                TextField("New category name", text: $newCategory)
                                    .textFieldStyle(.roundedBorder)
                                
                                Button(action: addNewCategory) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                }
                                .disabled(newCategory.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                            .padding(.horizontal)
                            
                            // Category List
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(categories, id: \.self) { category in
                                    HStack(spacing: 12) {
                                        Image(systemName: "folder.fill")
                                            .foregroundColor(.orange)
                                            .frame(width: 20)
                                        
                                        Text(category)
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        if !AutoOrganizeService.defaultCategories.contains(category) {
                                            Button(action: { removeCategory(category) }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .font(.body)
                                            }
                                        }
                                    }
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(6)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Organization Complete", isPresented: $showResult) {
                Button("OK") { showResult = false }
            } message: {
                Text("\(organizationResult.organized) jokes organized automatically\n\(organizationResult.suggested) jokes need manual categorization")
            }
        }
    }
    
    private func performAutoOrganize() {
        organizationResult = AutoOrganizeService.autoOrganizeAll(
            jokes: unorganizedJokes,
            folders: folders,
            modelContext: modelContext
        )
        showResult = true
    }
    
    private func addNewCategory() {
        let trimmed = newCategory.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        AutoOrganizeService.addCategory(trimmed)
        categories = AutoOrganizeService.getUserCategories()
        newCategory = ""
    }
    
    private func removeCategory(_ category: String) {
        AutoOrganizeService.removeCategory(category)
        categories = AutoOrganizeService.getUserCategories()
    }
}

// MARK: - Joke Organization Card

struct JokeOrganizeCard: View {
    let joke: Joke
    let onSelectCategory: (String) -> Void
    
    @State private var showMenu = false
    let categories = AutoOrganizeService.getUserCategories()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(joke.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
            
            Text(joke.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack(spacing: 8) {
                Menu {
                    ForEach(categories, id: \.self) { category in
                        Button(action: { onSelectCategory(category) }) {
                            Text(category)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.badge.plus")
                        Text("Select Category")
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

#Preview {
    AutoOrganizeView()
        .modelContainer(for: Joke.self, inMemory: true)
}
