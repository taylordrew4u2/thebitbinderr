//
//  RecordingsView.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/2/25.
//

import SwiftUI
import SwiftData
import AVFoundation

struct RecordingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recording.dateCreated, order: .reverse) private var recordings: [Recording]
    
    @State private var searchText = ""
    
    var filteredRecordings: [Recording] {
        if searchText.isEmpty {
            return recordings
        } else {
            return recordings.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if filteredRecordings.isEmpty {
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 100, height: 100)
                            Image(systemName: "mic.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.blue)
                        }
                        
                        VStack(spacing: 8) {
                            Text("No recordings yet")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Record a set list to see it here")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredRecordings) { recording in
                            NavigationLink(destination: RecordingDetailView(recording: recording)) {
                                RecordingRowView(recording: recording)
                            }
                        }
                        .onDelete(perform: deleteRecordings)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Recordings")
            .searchable(text: $searchText, prompt: "Search recordings")
        }
    }
    
    private func deleteRecordings(at offsets: IndexSet) {
        for index in offsets {
            let recording = filteredRecordings[index]
            let url = URL(fileURLWithPath: recording.fileURL)
            try? FileManager.default.removeItem(at: url)
            modelContext.delete(recording)
        }
    }
}

struct RecordingRowView: View {
    let recording: Recording
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: "play.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(recording.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(durationString(from: recording.duration))
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    
                    Text(recording.dateCreated, format: .dateTime.month(.abbreviated).day())
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 6)
    }
    
    private func durationString(from duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
