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
    
    @State private var categories: [String] = []
    @State private var newCategory = ""
    @State private var showingResults = false
    @State private var categorizationResults: [CategorizationResult] = []
    @State private var organizedCount = 0
    @State private var isOrganizing = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !showingResults {
                    // Setup View
                    setupView
                } else {
                    // Results View
                    resultsView
                }
            }
            .navigationTitle("Auto-Organize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !showingResults {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(showingResults ? "Close" : "Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                categories = AutoOrganizeService.getUserCategories()
            }
        }
    }
    
    // MARK: - Setup View
    
    private var setupView: some View {
        VStack(spacing: 0) {
            // Header Info
            VStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                Text("Auto-Organize All Jokes")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(jokes.count) jokes will be organized into folders")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            
            // Edit Categories Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Categories")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Reset to Defaults") {
                        AutoOrganizeService.resetToDefaults()
                        categories = AutoOrganizeService.getUserCategories()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
                .padding(.top)
                
                Text("Edit categories before organizing. Jokes will be sorted based on keywords.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // Add New Category
                HStack(spacing: 8) {
                    TextField("Add new category...", text: $newCategory)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: addCategory) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .disabled(newCategory.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal)
            }
            
            // Category List
            List {
                ForEach(categories, id: \.self) { category in
                    HStack(spacing: 12) {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.orange)
                        
                        Text(category)
                            .font(.body)
                        
                        Spacer()
                        
                        // Show joke count for this category
                        let count = jokes.filter { $0.folder?.name == category }.count
                        if count > 0 {
                            Text("\(count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray5))
                                .cornerRadius(10)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            removeCategory(category)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onMove(perform: moveCategories)
            }
            .listStyle(.plain)
            
            // Organize Button
            VStack(spacing: 12) {
                Button(action: organizeAllJokes) {
                    HStack(spacing: 12) {
                        if isOrganizing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "sparkles")
                        }
                        
                        Text(isOrganizing ? "Organizing..." : "Organize All Jokes")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(categories.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(12)
                }
                .disabled(categories.isEmpty || isOrganizing)
                .padding(.horizontal)
                
                Text("This will sort all \(jokes.count) jokes into folders based on content")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
    
    // MARK: - Results View
    
    private var resultsView: some View {
        VStack(spacing: 0) {
            // Success Header
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                
                Text("Organization Complete!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Successfully organized \(organizedCount) jokes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            
            // Categorization Results
            List {
                Section {
                    ForEach(groupResultsByCategory(), id: \.category) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.orange)
                                
                                Text(group.category)
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("\(group.count)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            
                            if let sample = group.sample {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Example reasoning:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "sparkles")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                        
                                        Text(sample.reasoning)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .italic()
                                    }
                                    
                                    if !sample.matchedKeywords.isEmpty {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 4) {
                                                ForEach(sample.matchedKeywords.prefix(5), id: \.self) { keyword in
                                                    Text(keyword)
                                                        .font(.caption2)
                                                        .foregroundColor(.blue)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.blue.opacity(0.1))
                                                        .cornerRadius(4)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Categorization Summary")
                }
            }
            .listStyle(.insetGrouped)
        }
    }
    
    // MARK: - Helper Methods
    
    private func addCategory() {
        let trimmed = newCategory.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        if !categories.contains(trimmed) {
            categories.append(trimmed)
            AutoOrganizeService.saveUserCategories(categories)
        }
        newCategory = ""
    }
    
    private func removeCategory(_ category: String) {
        categories.removeAll { $0 == category }
        AutoOrganizeService.saveUserCategories(categories)
    }
    
    private func moveCategories(from source: IndexSet, to destination: Int) {
        categories.move(fromOffsets: source, toOffset: destination)
        AutoOrganizeService.saveUserCategories(categories)
    }
    
    private func organizeAllJokes() {
        isOrganizing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let result = AutoOrganizeService.organizeAllJokes(
                jokes: jokes,
                categories: categories,
                folders: folders,
                modelContext: modelContext
            )
            
            organizedCount = result.count
            categorizationResults = result.results
            
            isOrganizing = false
            showingResults = true
        }
    }
    
    private func groupResultsByCategory() -> [(category: String, count: Int, sample: CategorizationResult?)] {
        var groups: [String: [CategorizationResult]] = [:]
        
        for result in categorizationResults {
            groups[result.category, default: []].append(result)
        }
        
        return groups.map { (category: $0.key, count: $0.value.count, sample: $0.value.first) }
            .sorted { $0.count > $1.count }
    }
}

#Preview {
    AutoOrganizeView()
        .modelContainer(for: [Joke.self, JokeFolder.self], inMemory: true)
}
