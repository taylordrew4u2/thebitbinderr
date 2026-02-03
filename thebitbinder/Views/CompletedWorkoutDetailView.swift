//
//  CompletedWorkoutDetailView.swift
//  thebitbinder
//
//  Created by Taylor Drew on 2/1/26.
//

import SwiftUI
import SwiftData

struct CompletedWorkoutDetailView: View {
    let workout: GymWorkout
    
    @State private var selectedEntries: Set<Int> = []
    @State private var showingAddToJokesAlert = false
    @State private var selectedEntryForSave: String?
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var jokes: [Joke]
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(workout.workoutType.displayName)
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    if let dateCompleted = workout.dateCompleted {
                        Text(dateCompleted.formatted(date: .long, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 16)
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Workout info card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Workout Details")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Topic")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(workout.topic)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Premise")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(workout.outerQuestion)
                                        .font(.subheadline)
                                }
                            }
                            .padding(14)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Notes section
                        if let notes = workout.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "note.text")
                                        .foregroundColor(.orange)
                                    Text("Notes")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                
                                Text(notes)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(16)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        // Responses card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "list.bullet")
                                    .foregroundColor(.purple)
                                Text("Responses")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Text("\(workout.entries.count) total")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            ForEach(Array(workout.entries.enumerated()), id: \.offset) { index, entry in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.purple)
                                        .clipShape(Circle())
                                    
                                    Text(entry)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        selectedEntryForSave = entry
                                        showingAddToJokesAlert = true
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(12)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            // Navigation buttons
            VStack {
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(12)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                    
                    NavigationLink(destination: GymView().navigationBarBackButtonHidden(true)) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("Save to Jokes", isPresented: $showingAddToJokesAlert) {
            TextField("Joke title (optional)", text: .constant(""))
            Button("Save") {
                if let entry = selectedEntryForSave {
                    saveEntryAsJoke(entry)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Add this response to your Jokes collection?")
        }
    }
    
    private func saveEntryAsJoke(_ entry: String) {
        let newJoke = Joke(
            content: entry,
            title: "\(workout.workoutType.displayName) - \(workout.topic)"
        )
        modelContext.insert(newJoke)
        try? modelContext.save()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: GymWorkout.self, configurations: config)
    let sampleWorkout = GymWorkout(
        workoutType: .premiseExpansion,
        topic: "Coffee",
        outerQuestion: "Why does burnt water cost $6?"
    )
    sampleWorkout.entries = [
        "Because the suffering is part of the brand",
        "It's not the coffee, it's the anxiety disorder",
        "You're not paying for coffee, you're renting a desk"
    ]
    container.mainContext.insert(sampleWorkout)
    
    return NavigationStack {
        CompletedWorkoutDetailView(workout: sampleWorkout)
    }
    .modelContainer(container)
}
