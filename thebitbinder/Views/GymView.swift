//
//  GymView.swift
//  thebitbinder
//
//  Created by Taylor Drew on 2/1/26.
//

import SwiftUI

struct GymView: View {
    @State private var showingWorkouts = false
    @State private var showingCompletedWorkouts = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.05), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Hero Header
                    VStack(spacing: 16) {
                        // Icon combo
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "dumbbell.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.blue)
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.red)
                            }
                        }
                        
                        VStack(spacing: 6) {
                            Text("Comedy Gym")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Train your comedy muscles")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 30)
                    
                    // Main menu cards
                    VStack(spacing: 16) {
                        NavigationLink(destination: WorkoutsListView()) {
                            GymMenuCard(
                                icon: "flame.fill",
                                iconColor: .orange,
                                title: "Start Workout",
                                subtitle: "Choose a workout and start writing",
                                badge: "4 types"
                            )
                        }
                        
                        NavigationLink(destination: CompletedWorkoutsView()) {
                            GymMenuCard(
                                icon: "trophy.fill",
                                iconColor: .yellow,
                                title: "Your History",
                                subtitle: "Review past workouts and progress",
                                badge: nil
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Quick tips
                    VStack(spacing: 12) {
                        Text("💡 Quick Tips")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        
                        Text("Start with Premise Expansion to generate multiple punchlines from one setup")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Menu Card Component
struct GymMenuCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let badge: String?
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let badge = badge {
                        Text(badge)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    GymView()
        .modelContainer(for: GymWorkout.self, inMemory: true)
}
