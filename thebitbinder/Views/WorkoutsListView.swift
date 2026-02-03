//
//  WorkoutsListView.swift
//  thebitbinder
//
//  Created by Taylor Drew on 2/1/26.
//

import SwiftUI

struct WorkoutsListView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Choose Your Workout")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Each workout targets a different comedy skill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                // Workout types
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(WorkoutType.allCases, id: \.self) { workoutType in
                            NavigationLink(destination: WorkoutConfigView(workoutType: workoutType)) {
                                WorkoutTypeCard(workoutType: workoutType)
                            }
                        }
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
}

// MARK: - Workout Type Card
struct WorkoutTypeCard: View {
    let workoutType: WorkoutType
    
    var iconName: String {
        switch workoutType {
        case .premiseExpansion: return "arrow.up.left.and.arrow.down.right"
        case .observationCompression: return "arrow.down.right.and.arrow.up.left"
        case .assumptionFlips: return "arrow.triangle.2.circlepath"
        case .tagStacking: return "square.stack.3d.up.fill"
        }
    }
    
    var iconColor: Color {
        switch workoutType {
        case .premiseExpansion: return .orange
        case .observationCompression: return .purple
        case .assumptionFlips: return .green
        case .tagStacking: return .blue
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Top row: Icon + Title + Reps badge
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(workoutType.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(workoutType.requiredReps) \(workoutType.requiredReps == 1 ? "rep" : "reps") to complete")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            
            // Description
            Text(workoutType.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            // Difficulty indicator
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(index < difficultyLevel ? iconColor : Color.gray.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
                Text(difficultyText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    var difficultyLevel: Int {
        switch workoutType {
        case .premiseExpansion: return 2
        case .observationCompression: return 3
        case .assumptionFlips: return 2
        case .tagStacking: return 1
        }
    }
    
    var difficultyText: String {
        switch difficultyLevel {
        case 1: return "Beginner"
        case 2: return "Intermediate"
        case 3: return "Advanced"
        default: return ""
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutsListView()
    }
}
