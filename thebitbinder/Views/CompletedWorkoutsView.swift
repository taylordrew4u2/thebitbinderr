//
//  CompletedWorkoutsView.swift
//  thebitbinder
//
//  Created by Taylor Drew on 2/1/26.
//

import SwiftUI
import SwiftData

struct CompletedWorkoutsView: View {
    @Query(sort: [SortDescriptor(\GymWorkout.dateCompleted, order: .reverse)]) 
    private var completedWorkouts: [GymWorkout]
    
    @State private var filterByType: WorkoutType?
    @State private var sortByDate = true
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var filteredWorkouts: [GymWorkout] {
        let completed = completedWorkouts.filter { $0.isCompleted }
        if let filter = filterByType {
            return completed.filter { $0.workoutType == filter }
        }
        return completed
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Your Progress")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(filteredWorkouts.count) workout\(filteredWorkouts.count == 1 ? "" : "s") completed")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)
                .padding(.bottom, 16)
                
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(title: "All", isSelected: filterByType == nil) {
                            filterByType = nil
                        }
                        
                        ForEach(WorkoutType.allCases, id: \.self) { type in
                            FilterChip(title: type.displayName, isSelected: filterByType == type) {
                                filterByType = type
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                
                Divider()
                
                // Workouts list
                if filteredWorkouts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No completed workouts yet")
                            .font(.headline)
                        Text("Complete a workout to see it here")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(filteredWorkouts, id: \.id) { workout in
                                NavigationLink(destination: CompletedWorkoutDetailView(workout: workout)) {
                                    CompletedWorkoutCard(workout: workout)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
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
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemBackground))
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(isSelected ? 0 : 0.05), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Completed Workout Card
struct CompletedWorkoutCard: View {
    let workout: GymWorkout
    
    var iconColor: Color {
        switch workout.workoutType {
        case .premiseExpansion: return .orange
        case .observationCompression: return .purple
        case .assumptionFlips: return .green
        case .tagStacking: return .blue
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(iconColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.workoutType.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(workout.topic)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let dateCompleted = workout.dateCompleted {
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text(dateCompleted.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            Spacer()
            
            // Response count
            VStack(spacing: 2) {
                Text("\(workout.entries.count)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Text("reps")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        CompletedWorkoutsView()
    }
    .modelContainer(for: GymWorkout.self, inMemory: true)
}
