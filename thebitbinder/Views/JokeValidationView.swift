//
//  JokeValidationView.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/9/25.
//

import SwiftUI

struct JokeValidationView: View {
    @Binding var candidates: [JokeImportCandidate]
    @Binding var currentIndex: Int
    let selectedFolder: JokeFolder?
    let onSave: (JokeImportCandidate) -> Void
    let onDismiss: () -> Void
    
    @State private var editedContent: String = ""
    @State private var editedTitle: String = ""
    @State private var showingSkipConfirm = false
    
    var currentCandidate: JokeImportCandidate? {
        guard currentIndex < candidates.count else { return nil }
        return candidates[currentIndex]
    }
    
    var body: some View {
        NavigationStack {
            if let candidate = currentCandidate {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Progress indicator
                        HStack {
                            Text("Joke \(currentIndex + 1) of \(candidates.count)")
                                .font(.headline)
                            Spacer()
                            ProgressView(value: Double(currentIndex + 1), total: Double(candidates.count))
                                .frame(width: 100)
                        }
                        .padding(.horizontal)
                        
                        // Status badge
                        HStack {
                            Image(systemName: candidate.isComplete ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(candidate.isComplete ? .green : (candidate.confidence >= 0.6 ? .orange : .red))
                            Text(candidate.statusDescription)
                                .font(.subheadline)
                        }
                        .padding(.horizontal)
                        
                        // Issues if any
                        if !candidate.issues.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Potential Issues:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                ForEach(candidate.issues, id: \.self) { issue in
                                    HStack(alignment: .top) {
                                        Image(systemName: "exclamationmark.circle")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                        Text(issue)
                                            .font(.caption)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                        
                        // Title field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Title")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Joke title", text: $editedTitle)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding(.horizontal)
                        
                        // Content field
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Joke Content")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                if candidate.suggestedFix != nil && editedContent != candidate.suggestedFix {
                                    Button("Apply Fix") {
                                        editedContent = candidate.suggestedFix ?? editedContent
                                    }
                                    .font(.caption)
                                }
                            }
                            
                            TextEditor(text: $editedContent)
                                .frame(minHeight: 150)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3))
                                )
                        }
                        .padding(.horizontal)
                        
                        // Confidence score
                        HStack {
                            Text("Confidence:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(candidate.confidence * 100))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(candidate.confidence >= 0.7 ? .green : (candidate.confidence >= 0.5 ? .orange : .red))
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.vertical)
                }
                .navigationTitle("Verify Joke")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            onDismiss()
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 12) {
                        // Save button
                        Button {
                            saveCurrentJoke()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save & Continue")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        HStack(spacing: 12) {
                            // Skip button
                            Button {
                                showingSkipConfirm = true
                            } label: {
                                HStack {
                                    Image(systemName: "forward.fill")
                                    Text("Skip")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                            
                            // Save All Remaining
                            if candidates.count > 1 && currentIndex < candidates.count - 1 {
                                Button {
                                    saveAllRemaining()
                                } label: {
                                    HStack {
                                        Image(systemName: "checkmark.circle")
                                        Text("Save All")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                }
                .onAppear {
                    loadCurrentCandidate()
                }
                .onChange(of: currentIndex) { _, _ in
                    loadCurrentCandidate()
                }
                .alert("Skip this joke?", isPresented: $showingSkipConfirm) {
                    Button("Skip", role: .destructive) {
                        skipCurrent()
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This joke won't be saved. You can always import it again later.")
                }
            } else {
                // Done - all jokes processed
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("All Done!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("All jokes have been processed.")
                        .foregroundColor(.secondary)
                    
                    Button("Close") {
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .navigationTitle("Import Complete")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    private func loadCurrentCandidate() {
        guard let candidate = currentCandidate else { return }
        editedContent = candidate.content
        editedTitle = candidate.suggestedTitle
    }
    
    private func saveCurrentJoke() {
        guard currentIndex < candidates.count else { return }
        
        var updatedCandidate = candidates[currentIndex]
        updatedCandidate.content = editedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedCandidate.suggestedTitle = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedCandidate.userApproved = true
        updatedCandidate.userEdited = (editedContent != candidates[currentIndex].content)
        
        // Only save if there's actual content
        if !updatedCandidate.content.isEmpty && !updatedCandidate.suggestedTitle.isEmpty {
            onSave(updatedCandidate)
        }
        
        // Move to next
        moveToNext()
    }
    
    private func skipCurrent() {
        moveToNext()
    }
    
    private func moveToNext() {
        if currentIndex < candidates.count - 1 {
            currentIndex += 1
        } else {
            // Done with all candidates
            currentIndex = candidates.count // This will trigger the "All Done" view
        }
    }
    
    private func saveAllRemaining() {
        // Save current one first
        saveCurrentJoke()
        
        // Save all remaining
        for i in currentIndex..<candidates.count {
            let candidate = candidates[i]
            if !candidate.content.isEmpty && !candidate.suggestedTitle.isEmpty {
                onSave(candidate)
            }
        }
        
        // Mark as complete
        currentIndex = candidates.count
    }
}

#Preview {
    JokeValidationView(
        candidates: .constant([
            JokeImportCandidate(
                content: "Why did the chicken cross the road? To get to the other side!",
                suggestedTitle: "Why did the chicken cross the road",
                isComplete: true,
                confidence: 0.95,
                issues: [],
                suggestedFix: nil
            ),
            JokeImportCandidate(
                content: "A man walks into a bar and",
                suggestedTitle: "A man walks into a bar",
                isComplete: false,
                confidence: 0.45,
                issues: ["Ends with 'and' - likely cut off", "Missing ending punctuation"],
                suggestedFix: "A man walks into a bar and..."
            )
        ]),
        currentIndex: .constant(0),
        selectedFolder: nil,
        onSave: { _ in },
        onDismiss: { }
    )
}
