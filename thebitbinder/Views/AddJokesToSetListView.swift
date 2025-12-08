//
//  AddJokesToSetListView.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/2/25.
//

import SwiftUI
import SwiftData

struct AddJokesToSetListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var jokes: [Joke]
    
    @Bindable var setList: SetList
    var currentJokeIDs: [UUID]
    
    @State private var selectedJokeIDs: Set<UUID> = []
    @State private var searchText = ""
    
    var availableJokes: [Joke] {
        let filtered = jokes.filter { joke in
            !currentJokeIDs.contains(joke.id)
        }
        
        if searchText.isEmpty {
            return filtered
        } else {
            return filtered.filter { joke in
                joke.title.localizedCaseInsensitiveContains(searchText) ||
                joke.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if availableJokes.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No jokes available")
                            .font(.title3)
                            .foregroundColor(.gray)
                        Text("All your jokes are already in this set list")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(availableJokes) { joke in
                        Button(action: {
                            if selectedJokeIDs.contains(joke.id) {
                                selectedJokeIDs.remove(joke.id)
                            } else {
                                selectedJokeIDs.insert(joke.id)
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(joke.title)
                                        .font(.headline)
                                    Text(joke.content)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                                if selectedJokeIDs.contains(joke.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Add Jokes")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search jokes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add (\(selectedJokeIDs.count))") {
                        addJokes()
                    }
                    .disabled(selectedJokeIDs.isEmpty)
                }
            }
        }
    }
    
    private func addJokes() {
        setList.jokeIDs.append(contentsOf: selectedJokeIDs)
        setList.dateModified = Date()
        dismiss()
    }
}
