//
//  WorkoutExecutionView.swift
//  thebitbinder
//
//  Created by Taylor Drew on 2/1/26.
//

import SwiftUI
import SwiftData

struct WorkoutExecutionView: View {
    let workoutType: WorkoutType
    let topic: String
    let outerQuestion: String
    let sourceJokeId: UUID?
    
    @State private var newEntry: String = ""
    @State private var entries: [String] = []
    @State private var notes: String = ""
    @State private var workout: GymWorkout?
    @State private var showCompletionAlert = false
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with progress
                VStack(spacing: 12) {
                    Text(workoutType.displayName)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    // Progress indicator
                    HStack(spacing: 8) {
                        ForEach(0..<workoutType.requiredReps, id: \.self) { index in
                            Circle()
                                .fill(index < entries.count ? Color.blue : Color.gray.opacity(0.2))
                                .frame(width: 10, height: 10)
                        }
                    }
                    
                    Text("\(entries.count)/\(workoutType.requiredReps) responses")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)
                .padding(.bottom, 16)
                
                // Workout content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Premise card
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                Text("Your Premise")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            Text(outerQuestion)
                                .font(.body)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Input card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Response \(entries.count + 1)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                if entries.count >= workoutType.requiredReps {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Complete!")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            
                            Text(instructionText())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            TextEditor(text: $newEntry)
                                .frame(height: 100)
                                .padding(10)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            Button(action: addEntry) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Response")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(newEntry.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(newEntry.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Responses list
                        if !entries.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Responses")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                                    HStack(alignment: .top, spacing: 12) {
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .frame(width: 24, height: 24)
                                            .background(Color.blue)
                                            .clipShape(Circle())
                                        
                                        Text(entry)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Button(action: { removeEntry(at: index) }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red.opacity(0.7))
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
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
                
                // Finish button
                if entries.count >= workoutType.requiredReps {
                    Button(action: finishWorkout) {
                        HStack {
                            Image(systemName: "trophy.fill")
                            Text("Complete Workout")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
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
        .alert("Workout Complete", isPresented: $showCompletionAlert) {
            Button("View Completed Workouts") {
                // Navigate to completed workouts
                dismiss()
            }
            Button("Done") {
                dismiss()
            }
        } message: {
            Text("Great work! You've completed \(workoutType.displayName)")
        }
        .onAppear {
            createWorkout()
        }
    }
    
    // MARK: - Helper Methods
    private func instructionText() -> String {
        switch workoutType {
        case .premiseExpansion:
            return "Write 10 different punchlines using this setup each time"
        case .observationCompression:
            return "Compress this paragraph into a single, punchy line"
        case .assumptionFlips:
            return "Argue the opposite of this belief as if it's obvious"
        case .tagStacking:
            return "Write 10 alternative tags/punchlines without changing the core joke"
        }
    }
    
    private func addEntry() {
        let trimmed = newEntry.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        entries.append(trimmed)
        newEntry = ""
        
        // Update the workout in the database
        if let workout = workout {
            workout.addEntry(trimmed)
            try? modelContext.save()
        }
    }
    
    private func removeEntry(at index: Int) {
        entries.remove(at: index)
        if let workout = workout {
            workout.removeEntry(at: index)
            try? modelContext.save()
        }
    }
    
    private func createWorkout() {
        let newWorkout = GymWorkout(
            workoutType: workoutType,
            topic: topic,
            outerQuestion: outerQuestion,
            sourceJokeId: sourceJokeId
        )
        modelContext.insert(newWorkout)
        try? modelContext.save()
        self.workout = newWorkout
    }
    
    private func finishWorkout() {
        if let workout = workout {
            workout.markComplete()
            try? modelContext.save()
        }
        showCompletionAlert = true
    }
}

#Preview {
    NavigationStack {
        WorkoutExecutionView(
            workoutType: .premiseExpansion,
            topic: "Coffee",
            outerQuestion: "Why does burnt water cost $6?",
            sourceJokeId: nil
        )
    }
    .modelContainer(for: GymWorkout.self, inMemory: true)
}
