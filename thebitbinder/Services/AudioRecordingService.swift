//
//  AudioRecordingService.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/2/25.
//

import AVFoundation
import UIKit
import Foundation
import Combine

class AudioRecordingService: NSObject, ObservableObject {
    
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var recordingTime: TimeInterval = 0
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    private var pausedDuration: TimeInterval = 0
    
    var recordingURL: URL? {
        return audioRecorder?.url
    }
    
    override init() {
        super.init()
        setupAudioSession()
        setupMemoryWarningObserver()
    }
    
    deinit {
        cleanup()
        NotificationCenter.default.removeObserver(self)
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
        // Stop recording if memory is low
        if isRecording {
            print("⚠️ Memory warning during recording - consider stopping")
        }
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func startRecording(fileName: String) -> Bool {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFileName = documentsPath.appendingPathComponent("\(fileName).m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFileName, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            isPaused = false
            recordingStartTime = Date()
            recordingTime = 0
            pausedDuration = 0
            
            // Start timer to update recording time
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let startTime = self.recordingStartTime else { return }
                self.recordingTime = Date().timeIntervalSince(startTime) - self.pausedDuration
            }
            
            return true
        } catch {
            print("Failed to start recording: \(error)")
            return false
        }
    }
    
    func pauseRecording() {
        guard isRecording && !isPaused else { return }
        audioRecorder?.pause()
        isPaused = true
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    func resumeRecording() {
        guard isRecording && isPaused else { return }
        audioRecorder?.record()
        isPaused = false
        
        // Restart timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            self.recordingTime = Date().timeIntervalSince(startTime) - self.pausedDuration
        }
    }
    
    func stopRecording() -> (url: URL?, duration: TimeInterval) {
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        let duration = recordingTime
        let url = audioRecorder?.url
        
        isRecording = false
        isPaused = false
        recordingTime = 0
        recordingStartTime = nil
        pausedDuration = 0
        
        return (url, duration)
    }
    
    func cancelRecording() {
        if let url = audioRecorder?.url {
            audioRecorder?.stop()
            try? FileManager.default.removeItem(at: url)
        }
        
        cleanup()
    }
    
    private func cleanup() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        isPaused = false
        recordingTime = 0
        recordingStartTime = nil
        pausedDuration = 0
        audioRecorder = nil
    }
}

extension AudioRecordingService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed")
        }
        cleanup()
    }
}
