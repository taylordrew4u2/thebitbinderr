//
//  RecordingDetailView.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/2/25.
//

import SwiftUI
import AVFoundation
import SwiftData
import Combine

struct RecordingDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var setLists: [SetList]
    
    @Bindable var recording: Recording
    @StateObject private var audioPlayer = AudioPlayerService()
    @State private var isTranscribing = false
    @State private var transcriptionError: String?
    @State private var showingTranscriptionError = false
    
    var setList: SetList? {
        guard let setListID = recording.setListID else { return nil }
        return setLists.first { $0.id == setListID }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Player controls
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.blue, lineWidth: 8)
                            .frame(width: 200, height: 200)
                        
                        if audioPlayer.isPlaying {
                            Circle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 180, height: 180)
                        }
                        
                        Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                    }
                    
                    // Progress bar
                    VStack(spacing: 8) {
                        Slider(value: $audioPlayer.currentTime, in: 0...max(audioPlayer.duration, 1), onEditingChanged: { editing in
                            if !editing {
                                audioPlayer.seek(to: audioPlayer.currentTime)
                            }
                        })
                        .tint(.blue)
                        
                        HStack {
                            Text(timeString(from: audioPlayer.currentTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(timeString(from: audioPlayer.duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Playback controls
                    HStack(spacing: 40) {
                        Button(action: { audioPlayer.seek(to: max(0, audioPlayer.currentTime - 15)) }) {
                            Image(systemName: "gobackward.15")
                                .font(.system(size: 30))
                        }
                        
                        Button(action: togglePlayback) {
                            Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 60))
                        }
                        
                        Button(action: { audioPlayer.seek(to: min(audioPlayer.duration, audioPlayer.currentTime + 15)) }) {
                            Image(systemName: "goforward.15")
                                .font(.system(size: 30))
                        }
                    }
                    .foregroundColor(.blue)
                }
                .padding()
                
                // Transcription section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Transcription", systemImage: "text.quote")
                            .font(.headline)
                        
                        Spacer()
                        
                        if isTranscribing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if recording.transcription == nil {
                            Button(action: transcribeRecording) {
                                Label("Transcribe", systemImage: "waveform")
                                    .font(.subheadline)
                            }
                        } else {
                            Button(action: transcribeRecording) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.subheadline)
                            }
                        }
                    }
                    
                    if let transcription = recording.transcription {
                        Text(transcription)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(10)
                    } else if isTranscribing {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                ProgressView()
                                Text("Transcribing audio...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                    } else {
                        Text("Tap 'Transcribe' to convert this recording to text")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Recording info
                VStack(alignment: .leading, spacing: 16) {
                    InfoRow(label: "Name", value: recording.name)
                    InfoRow(label: "Duration", value: timeString(from: recording.duration))
                    InfoRow(label: "Date", value: recording.dateCreated.formatted(date: .long, time: .shortened))
                    
                    if let setList = setList {
                        NavigationLink(destination: SetListDetailView(setList: setList)) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Set List")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(setList.name)
                                        .font(.body)
                                        .foregroundColor(.blue)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Share button
                Button(action: shareRecording) {
                    Label("Share Recording", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Recording")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            audioPlayer.loadAudio(from: recording.fileURL)
        }
        .onDisappear {
            audioPlayer.stop()
        }
        .alert("Transcription Error", isPresented: $showingTranscriptionError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(transcriptionError ?? "An unknown error occurred")
        }
    }
    
    private func togglePlayback() {
        if audioPlayer.isPlaying {
            audioPlayer.pause()
        } else {
            audioPlayer.play()
        }
    }
    
    private func transcribeRecording() {
        isTranscribing = true
        transcriptionError = nil
        
        Task {
            do {
                let url = URL(fileURLWithPath: recording.fileURL)
                let result = try await AudioTranscriptionService.shared.transcribe(audioURL: url)
                
                await MainActor.run {
                    recording.transcription = result.transcription
                    try? modelContext.save()
                    isTranscribing = false
                }
            } catch {
                await MainActor.run {
                    transcriptionError = error.localizedDescription
                    showingTranscriptionError = true
                    isTranscribing = false
                }
            }
        }
    }
    
    private func shareRecording() {
        let url = URL(fileURLWithPath: recording.fileURL)
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
    }
}

class AudioPlayerService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    override init() {
        super.init()
        setupAudioSession()
        setupMemoryWarningObserver()
    }
    
    deinit {
        cleanup()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        // Pause playback on memory warning
        if isPlaying {
            pause()
            print("⚠️ Memory warning - pausing playback")
        }
    }
    
    func loadAudio(from path: String) {
        // Clean up previous audio first
        cleanup()
        
        let url = URL(fileURLWithPath: path)
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: path) else {
            print("Audio file does not exist at path: \(path)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
        } catch {
            print("Error loading audio: \(error.localizedDescription)")
        }
    }
    
    func play() {
        audioPlayer?.play()
        isPlaying = true
        startTimer()
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        currentTime = 0
        stopTimer()
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
            
            if !player.isPlaying && self.isPlaying {
                self.isPlaying = false
                self.stopTimer()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func cleanup() {
        stopTimer()
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
    }
    
    // AVAudioPlayerDelegate methods
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = 0
        stopTimer()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("Audio player decode error: \(error.localizedDescription)")
        }
        isPlaying = false
        stopTimer()
    }
}
