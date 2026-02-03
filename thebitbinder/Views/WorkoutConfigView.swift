//
//  WorkoutConfigView.swift
//  thebitbinder
//
//  Created by Taylor Drew on 2/1/26.
//

import SwiftUI

struct WorkoutConfigView: View {
    let workoutType: WorkoutType
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTopic: String = ""
    @State private var selectedQuestion: String = ""
    @State private var showTopicInput = false
    @State private var customTopic = ""
    @State private var showQuestionSelection = false
    @State private var availableQuestions: [String] = []
    @State private var useRandomTopic = false
    @State private var sourceJokeId: UUID?
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text(workoutType.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Set up your workout")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                // Configuration content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Step 1: Topic selection
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Text("1")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                
                                Text("Choose a Topic")
                                    .font(.headline)
                            }
                            
                            switch workoutType {
                            case .premiseExpansion, .observationCompression:
                                topicSelectionView()
                                
                            case .assumptionFlips:
                                beliefSelectionView()
                                
                            case .tagStacking:
                                jokeSelectionView()
                            }
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Step 2: Question selection
                        if !selectedTopic.isEmpty || sourceJokeId != nil {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Text("2")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                    
                                    Text("Select an Outsider Question")
                                        .font(.headline)
                                }
                                
                                Text("These naive perspectives become your comedy premise")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                if availableQuestions.isEmpty {
                                    Button(action: loadQuestions) {
                                        HStack {
                                            Image(systemName: "sparkles")
                                            Text("Generate Questions")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                } else {
                                    VStack(spacing: 10) {
                                        ForEach(availableQuestions, id: \.self) { question in
                                            Button(action: { selectedQuestion = question }) {
                                                HStack {
                                                    Text(question)
                                                        .font(.subheadline)
                                                        .multilineTextAlignment(.leading)
                                                        .foregroundColor(.primary)
                                                    
                                                    Spacer()
                                                    
                                                    if selectedQuestion == question {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .foregroundColor(.blue)
                                                    } else {
                                                        Circle()
                                                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                                            .frame(width: 22, height: 22)
                                                    }
                                                }
                                                .padding(14)
                                                .background(selectedQuestion == question ? Color.blue.opacity(0.08) : Color(.systemGray6))
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            }
                                        }
                                    }
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
                
                // Start button
                if !selectedQuestion.isEmpty {
                    NavigationLink(
                        destination: WorkoutExecutionView(
                            workoutType: workoutType,
                            topic: selectedTopic,
                            outerQuestion: selectedQuestion,
                            sourceJokeId: sourceJokeId
                        )
                    ) {
                        HStack {
                            Image(systemName: "flame.fill")
                            Text("Start Workout")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
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
    }
    
    // MARK: - Topic Selection Views
    @ViewBuilder
    private func topicSelectionView() -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: { useRandomTopic = true; selectedTopic = GymService.shared.generateRandomTopic(); loadQuestions() }) {
                    HStack {
                        Image(systemName: "dice.fill")
                        Text("Random Topic")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(useRandomTopic ? Color.blue : Color(.systemGray6))
                    .foregroundColor(useRandomTopic ? .white : .black)
                    .cornerRadius(8)
                }
                
                Button(action: { showTopicInput = true; useRandomTopic = false }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Enter Topic")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(!useRandomTopic && !customTopic.isEmpty ? Color.blue : Color(.systemGray6))
                    .foregroundColor(!useRandomTopic && !customTopic.isEmpty ? .white : .black)
                    .cornerRadius(8)
                }
            }
            
            if showTopicInput {
                TextField("Enter a topic", text: $customTopic, onEditingChanged: { _ in
                    if !customTopic.isEmpty {
                        selectedTopic = customTopic
                        loadQuestions()
                    }
                })
                .textFieldStyle(.roundedBorder)
                .padding(8)
            }
            
            if !selectedTopic.isEmpty {
                Text("Selected: \(selectedTopic)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
    
    @ViewBuilder
    private func beliefSelectionView() -> some View {
        VStack(spacing: 12) {
            Text("For Assumption Flips, enter a common belief")
                .font(.caption)
                .foregroundColor(.gray)
            
            TextField("e.g., Money buys happiness", text: $customTopic)
                .textFieldStyle(.roundedBorder)
            
            if !customTopic.isEmpty {
                Button(action: {
                    selectedTopic = customTopic
                    availableQuestions = ["Opposite: \(generateOpposite(for: customTopic))"]
                    if availableQuestions.count > 0 {
                        selectedQuestion = availableQuestions[0]
                    }
                }) {
                    Text("Generate Opposite")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    @ViewBuilder
    private func jokeSelectionView() -> some View {
        VStack(spacing: 12) {
            Text("For Tag Stacking, select or create a joke")
                .font(.caption)
                .foregroundColor(.gray)
            
            NavigationLink(destination: SelectJokeForTagStackingView(selectedJokeId: $sourceJokeId)) {
                HStack {
                    Image(systemName: "text.bubble.fill")
                    Text("Select Existing Joke")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color(.systemGray6))
                .foregroundColor(.black)
                .cornerRadius(8)
            }
            
            Divider()
            
            TextField("Or type a new joke here...", text: $customTopic)
                .textFieldStyle(.roundedBorder)
                .onChange(of: customTopic) { oldValue, newValue in
                    if !newValue.isEmpty {
                        selectedTopic = newValue
                        selectedQuestion = newValue  // Use joke as the question
                    }
                }
        }
    }
    
    // MARK: - Helper Methods
    private func loadQuestions() {
        availableQuestions = GymService.shared.generateOutsiderQuestions(forTopic: selectedTopic, count: 5)
    }
    
    private func generateOpposite(for belief: String) -> String {
        // Simple opposite generation
        return "Actually, \(belief.lowercased()) is false"
    }
}

#Preview {
    NavigationStack {
        WorkoutConfigView(workoutType: .premiseExpansion)
    }
    .modelContainer(for: GymWorkout.self, inMemory: true)
}
