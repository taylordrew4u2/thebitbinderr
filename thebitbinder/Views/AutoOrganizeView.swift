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
    
    var unorganizedJokes: [Joke] {
        jokes.filter { $0.folder == nil }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Unorganized Jokes Section
                        if !unorganizedJokes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Unorganized Jokes (\(unorganizedJokes.count))")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(unorganizedJokes) { joke in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(joke.title)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        
                                        Text(joke.content)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                        
                                        Menu {
                                            ForEach(categories, id: \.self) { category in
                                                Button(category) {
                                                    organizeJoke(joke, into: category)
                                                }
                                            }
                                        } label: {
                                            Text("Select Category")
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.blue)
                                                .foregroundColor(.white)
                                                .cornerRadius(6)
                                        }
                                    }
                                    .padding()
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                            .padding()
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.green)
                                Text("All Jokes Organized!")
                                    .font(.headline)
                                Text("Your jokes have been sorted into categories")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .padding()
                        }
                        
                        Divider()
                            .padding(.vertical)
                        
                        // Manage Categories Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Manage Categories")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                ForEach(categories, id: \.self) { category in
                                    HStack {
                                        Text(category)
                                            .font(.subheadline)
                                        Spacer()
                                        Button(action: { removeCategory(category) }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding()
                                    .background(Color(UIColor.systemBackground))
                                    .overlay(Divider(), alignment: .bottom)
                                }
                            }
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                            
                            HStack {
                                TextField("New category", text: $newCategory)
                                    .textFieldStyle(.roundedBorder)
                                
                                Button(action: addCategory) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 20))
                                }
                                .disabled(newCategory.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                    }
                    .padding(.vertical)
                }
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
    
    private func organizeJoke(_ joke: Joke, into category: String) {
        AutoOrganizeService.organizeJoke(
            joke,
            intoCategory: category,
            existingFolders: folders,
            modelContext: modelContext
        )
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
