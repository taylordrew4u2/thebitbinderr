//
//  GymWorkout.swift
//  thebitbinder
//
//  Created by Taylor Drew on 2/1/26.
//

import Foundation
import SwiftData

enum WorkoutType: String, Codable, CaseIterable {
    case premiseExpansion = "Premise Expansion"
    case observationCompression = "Observation Compression"
    case assumptionFlips = "Assumption Flips"
    case tagStacking = "Tag Stacking"
    
    var displayName: String {
        self.rawValue
    }
    
    var description: String {
        switch self {
        case .premiseExpansion:
            return "Write 10 different punchlines using the same setup"
        case .observationCompression:
            return "Compress a paragraph rant into one line"
        case .assumptionFlips:
            return "State a belief and argue the opposite"
        case .tagStacking:
            return "Write 10 tags without changing the core punchline"
        }
    }
    
    var requiredReps: Int {
        switch self {
        case .premiseExpansion, .tagStacking:
            return 10
        case .observationCompression:
            return 1
        case .assumptionFlips:
            return 2
        }
    }
}

@Model
final class GymWorkout {
    var id: UUID
    var workoutType: WorkoutType
    var dateStarted: Date
    var dateCompleted: Date?
    var isCompleted: Bool
    
    // Workout configuration
    var topic: String
    var outerQuestion: String  // The naive/outsider question selected
    var sourceJokeId: UUID?  // For tag stacking - reference to existing joke
    
    // User entries
    var entries: [String]  // List of responses/punchlines written
    var notes: String?  // Optional user annotations
    
    init(
        workoutType: WorkoutType,
        topic: String,
        outerQuestion: String,
        sourceJokeId: UUID? = nil
    ) {
        self.id = UUID()
        self.workoutType = workoutType
        self.dateStarted = Date()
        self.isCompleted = false
        self.topic = topic
        self.outerQuestion = outerQuestion
        self.sourceJokeId = sourceJokeId
        self.entries = []
        self.notes = nil
    }
    
    func markComplete() {
        self.isCompleted = true
        self.dateCompleted = Date()
    }
    
    func addEntry(_ entry: String) {
        self.entries.append(entry)
    }
    
    func removeEntry(at index: Int) {
        guard index >= 0 && index < entries.count else { return }
        self.entries.remove(at: index)
    }
    
    var isFullyCompleted: Bool {
        entries.count >= workoutType.requiredReps
    }
}
