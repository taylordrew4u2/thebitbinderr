//
//  ShareViewController.swift
//  VoiceMemoImport
//
//  Created by Taylor Drew on 1/4/26.
//

import UIKit
import Social
import UniformTypeIdentifiers
import AVFoundation
import Speech

class ShareViewController: UIViewController {
    
    private var audioURLs: [URL] = []
    private let transcriptionService = ShareExtensionTranscriptionService()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Import to thebitbinder"
        label.font = .boldSystemFont(ofSize: 18)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Processing audio..."
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        processSharedContent()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(activityIndicator)
        containerView.addSubview(statusLabel)
        containerView.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 280),
            containerView.heightAnchor.constraint(equalToConstant: 200),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            
            statusLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            cancelButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])
        
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        activityIndicator.startAnimating()
    }
    
    @objc private func cancelTapped() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    private func processSharedContent() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            showError("No content to import")
            return
        }
        
        let audioTypes = [
            UTType.audio.identifier,
            UTType.mpeg4Audio.identifier,
            UTType.mp3.identifier,
            UTType.wav.identifier,
            "com.apple.m4a-audio",
            "public.audio"
        ]
        
        var foundAudio = false
        
        for item in extensionItems {
            guard let attachments = item.attachments else { continue }
            
            for attachment in attachments {
                for audioType in audioTypes {
                    if attachment.hasItemConformingToTypeIdentifier(audioType) {
                        foundAudio = true
                        attachment.loadItem(forTypeIdentifier: audioType, options: nil) { [weak self] (item, error) in
                            if let error = error {
                                DispatchQueue.main.async {
                                    self?.showError("Failed to load audio: \(error.localizedDescription)")
                                }
                                return
                            }
                            
                            var audioURL: URL?
                            
                            if let url = item as? URL {
                                audioURL = url
                            } else if let data = item as? Data {
                                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
                                do {
                                    try data.write(to: tempURL)
                                    audioURL = tempURL
                                } catch {
                                    DispatchQueue.main.async {
                                        self?.showError("Failed to save audio: \(error.localizedDescription)")
                                    }
                                    return
                                }
                            }
                            
                            if let url = audioURL {
                                self?.transcribeAndSave(url: url)
                            }
                        }
                        break
                    }
                }
            }
        }
        
        if !foundAudio {
            showError("No audio file found")
        }
    }
    
    private func transcribeAndSave(url: URL) {
        DispatchQueue.main.async {
            self.statusLabel.text = "Transcribing audio..."
        }
        
        transcriptionService.transcribe(audioURL: url) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let transcription):
                    self?.saveToAppGroup(transcription: transcription, filename: url.lastPathComponent)
                case .failure(let error):
                    self?.showError("Transcription failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func saveToAppGroup(transcription: String, filename: String) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.taylordrew.thebitbinder")
        
        var pendingImports = sharedDefaults?.array(forKey: "pendingVoiceMemoImports") as? [[String: String]] ?? []
        
        let importData: [String: String] = [
            "transcription": transcription,
            "filename": filename,
            "date": ISO8601DateFormatter().string(from: Date())
        ]
        pendingImports.append(importData)
        
        sharedDefaults?.set(pendingImports, forKey: "pendingVoiceMemoImports")
        sharedDefaults?.synchronize()
        
        statusLabel.text = "Imported successfully!\nOpen thebitbinder to see your joke."
        activityIndicator.stopAnimating()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
    
    private func showError(_ message: String) {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.statusLabel.text = message
            self.statusLabel.textColor = .systemRed
        }
    }
}

// MARK: - Transcription Service for Share Extension

class ShareExtensionTranscriptionService {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    func transcribe(audioURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else {
                completion(.failure(NSError(domain: "SpeechRecognition", code: -1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition not authorized"])))
                return
            }
            
            guard let recognizer = self.speechRecognizer, recognizer.isAvailable else {
                completion(.failure(NSError(domain: "SpeechRecognition", code: -2, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available"])))
                return
            }
            
            let request = SFSpeechURLRecognitionRequest(url: audioURL)
            request.shouldReportPartialResults = false
            request.addsPunctuation = true
            
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let result = result, result.isFinal else { return }
                
                let transcription = result.bestTranscription.formattedString
                if transcription.isEmpty {
                    completion(.failure(NSError(domain: "SpeechRecognition", code: -3, userInfo: [NSLocalizedDescriptionKey: "No speech detected"])))
                } else {
                    completion(.success(transcription))
                }
            }
        }
    }
}
