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
    @State private var showOrganizationSummary = false
    @State private var organizationStats: (organized: Int, suggested: Int) = (0, 0)
    @State private var selectedJoke: Joke?
    @State private var showCategoryDetails = false
    
    var unorganizedJokes: [Joke] {
        jokes.filter { $0.folder == nil }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Quick Auto-Organize Button
                        if !unorganizedJokes.isEmpty {
                            Button(action: performAutoOrganize) {
                                HStack(spacing: 12) {
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 16, weight: .semibold))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Smart Auto-Organize")
                                            .font(.headline)
                                        Text("AI-powered categorization")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue.opacity(0.8), .blue.opacity(0.6)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(10)
                            }
                            .padding()
                        }
                        
                        // Unorganized Jokes Section
                        if !unorganizedJokes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Suggested Categories (\(unorganizedJokes.count))")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(unorganizedJokes) { joke in
                                    JokeOrganizationCard(
                                        joke: joke,
                                        onTap: {
                                            selectedJoke = joke
                                            showCategoryDetails = true
                                        },
                                        onAccept: { category in
                                            assignJokeToFolder(joke, category: category)
                                        }
                                    )
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
                                Text("Your jokes have been sorted into categories with confidence scoring")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .padding()
                        }
                        
                        if !unorganizedJokes.isEmpty {
                            Divider()
                                .padding(.vertical)
                        }
                        
                        // Category Management Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("All Categories")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 8) {
                                ForEach(categories, id: \.self) { category in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(category)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            let jokeCount = jokes.filter { $0.folder?.name == category }.count
                                            if jokeCount > 0 {
                                                Text("\(jokeCount) jokes")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: "folder.fill")
                                            .foregroundColor(.blue)
                                            .opacity(0.6)
                                    }
                                    .padding()
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Smart Auto-Organize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCategoryDetails) {
                if let joke = selectedJoke {
                    CategorySuggestionDetail(
                        joke: joke,
                        onSelectCategory: { category in
                            assignJokeToFolder(joke, category: category)
                            showCategoryDetails = false
                        }
                    )
                }
            }
            .alert("Organization Complete", isPresented: $showOrganizationSummary) {
                Button("Done") { }
            } message: {
                Text("✅ Organized: \(organizationStats.organized) jokes\n⚠️ Suggested: \(organizationStats.suggested) jokes")
            }
        }
    }
    
    private func performAutoOrganize() {
        AutoOrganizeService.autoOrganizeJokes(
            unorganizedJokes: unorganizedJokes,
            existingFolders: folders,
            modelContext: modelContext
        ) { organized, suggested in
            organizationStats = (organized, suggested)
            showOrganizationSummary = true
        }
    }
    
    private func assignJokeToFolder(_ joke: Joke, category: String) {
        var targetFolder = folders.first(where: { $0.name == category })
        
        if targetFolder == nil {
            targetFolder = JokeFolder(name: category)
            modelContext.insert(targetFolder!)
        }
        
        joke.folder = targetFolder
        try? modelContext.save()
    }
}

// MARK: - Joke Organization Card

struct JokeOrganizationCard: View {
    let joke: Joke
    let onTap: () -> Void
    let onAccept: (String) -> Void
    
    var topSuggestion: CategoryMatch? {
        joke.categorizationResults.first
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(joke.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
            
            Text(joke.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            if let suggestion = topSuggestion {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(suggestion.category)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            
                            Text(suggestion.reasoning)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(suggestion.confidencePercent)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(confidenceColor(suggestion.confidence))
                                .cornerRadius(6)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Button(action: { onAccept(suggestion.category) }) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle")
                                Text("Accept")
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .cornerRadius(6)
                        }
                        
                        Button(action: onTap) {
                            HStack(spacing: 6) {
                                Image(systemName: "pencil")
                                Text("Choose")
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                        }
                        
                        Spacer()
                    }
                }
                .padding(12)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
            } else {
                // No suggestion available
                VStack(alignment: .leading, spacing: 8) {
                    Text("No automatic suggestion")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: onTap) {
                        HStack(spacing: 6) {
                            Image(systemName: "folder.badge.plus")
                            Text("Choose Category")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                .padding(12)
                .background(Color.orange.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.8...:
            return .green
        case 0.6..<0.8:
            return .blue
        case 0.4..<0.6:
            return .orange
        default:
            return .gray
        }
    }
}

// MARK: - Category Suggestion Detail

struct CategorySuggestionDetail: View {
    @Environment(\.dismiss) var dismiss
    @State private var customFolderName: String = ""
    
    let joke: Joke
    let onSelectCategory: (String) -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text(joke.title)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(joke.content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
                .padding()
                
                Text("Smart Suggestions")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(joke.categorizationResults, id: \.category) { match in
                            Button(action: { onSelectCategory(match.category) }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(match.category)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            Text(match.reasoning)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing) {
                                            Text(match.confidencePercent)
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(confidenceColor(match.confidence))
                                                .cornerRadius(6)
                                        }
                                    }
                                    
                                    if !match.matchedKeywords.isEmpty {
                                        Wrap(match.matchedKeywords) { keyword in
                                            Text(keyword)
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.blue.opacity(0.1))
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        // Custom Folder Input
                        Divider().padding(.vertical)
                        Text("Create New Folder")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack {
                            TextField("New folder name...", text: $customFolderName)
                                .textFieldStyle(.roundedBorder)
                            Button(action: {
                                if !customFolderName.trimmingCharacters(in: .whitespaces).isEmpty {
                                    onSelectCategory(customFolderName.trimmingCharacters(in: .whitespaces))
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Choose Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.8...:
            return .green
        case 0.6..<0.8:
            return .blue
        case 0.4..<0.6:
            return .orange
        default:
            return .gray
        }
    }
}

// MARK: - Wrap Helper for Keyword Display

struct Wrap<Content: View>: View {
    let items: [String]
    let content: (String) -> Content
    
    init(_ items: [String], @ViewBuilder content: @escaping (String) -> Content) {
        self.items = items
        self.content = content
    }
    
    var body: some View {
        var width: CGFloat = .zero
        var height: CGFloat = .zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .alignmentGuide(.leading) { dimension in
                        if abs(width - dimension.width) > UIScreen.main.bounds.width - 32 {
                            width = 0
                            height -= dimension.height
                        }
                        let result = width
                        width -= dimension.width
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        return result
                    }
            }
        }
    }
}
