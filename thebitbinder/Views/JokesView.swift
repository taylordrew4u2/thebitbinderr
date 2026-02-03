//
//  JokesView.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/2/25.
//

import SwiftUI
import SwiftData
import PhotosUI
import PDFKit

struct JokesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var jokes: [Joke]
    @Query private var folders: [JokeFolder]
    
    @State private var showingAddJoke = false
    @State private var showingScanner = false
    @State private var showingImagePicker = false
    @State private var showingFilePicker = false
    @State private var showingCreateFolder = false
    @State private var showingAutoOrganize = false
    @State private var showingExportAlert = false
    @State private var selectedFolder: JokeFolder?
    @State private var searchText = ""
    @State private var exportedPDFURL: URL?
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isProcessingImages = false
    @State private var processingCurrent: Int = 0
    @State private var processingTotal: Int = 0
    @State private var importSummary: (added: Int, skipped: Int) = (0, 0)
    @State private var showingImportSummary = false
    @State private var folderPendingDeletion: JokeFolder?
    @State private var showingDeleteFolderAlert = false
    @State private var showingMoveJokesSheet = false
    @State private var showingAudioImport = false
    @State private var showingTalkToText = false
    
    @State private var reviewCandidates: [JokeImportCandidate] = []
    @State private var showingReviewSheet = false
    @State private var possibleDuplicates: [String] = [] // store brief descriptions

    @ViewBuilder
    private var folderChips: some View {
        if !folders.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FolderChip(
                        name: "All Jokes",
                        isSelected: selectedFolder == nil,
                        action: { selectedFolder = nil }
                    )
                    ForEach(folders) { folder in
                        FolderChip(
                            name: folder.name,
                            isSelected: selectedFolder?.id == folder.id,
                            action: { selectedFolder = folder }
                        )
                        .contextMenu {
                            Button(role: .destructive) {
                                folderPendingDeletion = folder
                                showingDeleteFolderAlert = true
                            } label: {
                                Label("Delete Folder", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.blue)
            }
            
            VStack(spacing: 8) {
                Text("No jokes yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("Add your first joke using the + button")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }

    
    var filteredJokes: [Joke] {
        // Start with base jokes depending on selected folder
        let base: [Joke]
        if let folder = selectedFolder {
            base = jokes.filter { $0.folder?.id == folder.id }
        } else {
            base = jokes
        }
        
        // Apply search filter if needed
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered: [Joke]
        if trimmed.isEmpty {
            filtered = base
        } else {
            let lower = trimmed.lowercased()
            filtered = base.filter { matchesSearch($0, lower: lower) }
        }
        
        // Sort by dateCreated descending (newest first)
        return filtered.sorted { $0.dateCreated > $1.dateCreated }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Folder selection
                folderChips
                
                Divider()
                
                // Jokes list
                if filteredJokes.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filteredJokes) { joke in
                            NavigationLink(destination: JokeDetailView(joke: joke)) {
                                JokeRowView(joke: joke)
                            }
                        }
                        .onDelete(perform: deleteJokes)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Jokes")
            .searchable(text: $searchText, prompt: "Search jokes")
            .onAppear {
                checkPendingVoiceMemoImports()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: { showingCreateFolder = true }) {
                            Label("New Folder", systemImage: "folder.badge.plus")
                        }
                        
                        Button(action: { showingAutoOrganize = true }) {
                            Label("Auto-Organize", systemImage: "wand.and.stars")
                        }
                        
                        Button(action: exportJokesToPDF) {
                            Label("Export to PDF", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAddJoke = true }) {
                            Label("Add Manually", systemImage: "square.and.pencil")
                        }
                        
                        Button(action: { showingTalkToText = true }) {
                            Label("Talk-to-Text", systemImage: "mic.badge.plus")
                        }
                        
                        Button(action: { showingScanner = true }) {
                            Label("Scan from Camera", systemImage: "camera")
                        }
                        
                        // Replaced inline PhotosPicker with a button that triggers .photosPicker modifier
                        Button(action: { showingImagePicker = true }) {
                            Label("Import Photos", systemImage: "photo.on.rectangle")
                        }
                        
                        Button(action: { showingAudioImport = true }) {
                            Label("Import Voice Memos", systemImage: "waveform")
                        }
                        
                        Button(action: { showingFilePicker = true }) {
                            Label("Import Files", systemImage: "doc")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            // Present Photos picker via iOS 17 API
            .photosPicker(isPresented: $showingImagePicker, selection: $selectedPhotos, matching: .images, preferredItemEncoding: .automatic)
            .onChange(of: selectedPhotos) { oldValue, newValue in
                Task {
                    await processSelectedPhotos(newValue)
                }
            }
            .sheet(isPresented: $showingAddJoke) {
                AddJokeView(selectedFolder: selectedFolder)
            }
            .sheet(isPresented: $showingScanner) {
                DocumentScannerView { images in
                    processScannedImages(images)
                }
            }
            .sheet(isPresented: $showingCreateFolder) {
                CreateFolderView()
            }
            .sheet(isPresented: $showingAutoOrganize) {
                AutoOrganizeView()
            }
            .sheet(isPresented: $showingAudioImport) {
                AudioImportView(selectedFolder: selectedFolder)
            }
            .sheet(isPresented: $showingTalkToText) {
                TalkToTextView(selectedFolder: selectedFolder)
            }
            .sheet(isPresented: $showingFilePicker) {
                DocumentPickerView { urls in
                    processDocuments(urls)
                }
            }
            .alert("PDF Exported", isPresented: $showingExportAlert) {
                if let url = exportedPDFURL {
                    Button("Share") {
                        shareFile(url)
                    }
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your jokes have been exported to a PDF file.")
            }
            .alert("Import Complete", isPresented: $showingImportSummary) {
                Button("OK") {}
            } message: {
                Text("Imported \(importSummary.added) jokes. Skipped \(importSummary.skipped).")
            }
            .alert("Delete Folder?", isPresented: $showingDeleteFolderAlert) {
                Button("Move Jokes…") {
                    showingMoveJokesSheet = true
                }
                Button("Remove From Folder", role: .destructive) {
                    if let folder = folderPendingDeletion {
                        removeJokesFromFolderAndDelete(folder)
                    }
                }
                Button("Cancel", role: .cancel) {
                    folderPendingDeletion = nil
                }
            } message: {
                let count = folderPendingDeletion.map { f in jokes.filter { $0.folder?.id == f.id }.count } ?? 0
                Text("This will delete the folder ‘\(folderPendingDeletion?.name ?? "")’. You can move its \(count) jokes to another folder, or remove them from any folder.")
            }
            .sheet(isPresented: $showingMoveJokesSheet) {
                NavigationStack {
                    List {
                        // Option to create an unassigned state
                        Button(action: {
                            if let folder = folderPendingDeletion {
                                moveJokes(from: folder, to: nil)
                                deleteFolder(folder)
                            }
                            showingMoveJokesSheet = false
                            folderPendingDeletion = nil
                        }) {
                            Label("Move to No Folder", systemImage: "tray")
                        }
                        
                        ForEach(folders) { dest in
                            // Prevent moving into the same folder
                            if dest.id != folderPendingDeletion?.id {
                                Button(action: {
                                    if let source = folderPendingDeletion {
                                        moveJokes(from: source, to: dest)
                                        deleteFolder(source)
                                    }
                                    showingMoveJokesSheet = false
                                    folderPendingDeletion = nil
                                }) {
                                    Label(dest.name, systemImage: "folder")
                                }
                            }
                        }
                    }
                    .navigationTitle("Move Jokes To…")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingMoveJokesSheet = false
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingReviewSheet) {
                NavigationStack {
                    List {
                        if !possibleDuplicates.isEmpty {
                            Section("Possible Duplicates") {
                                ForEach(possibleDuplicates, id: \.self) { dup in
                                    Label(dup, systemImage: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        Section("Needs Review") {
                            ForEach(Array(reviewCandidates.enumerated()), id: \.element.id) { index, cand in
                                VStack(alignment: .leading, spacing: 8) {
                                    TextField("Title", text: .constant(cand.suggestedTitle))
                                        .textFieldStyle(.roundedBorder)
                                    Text(cand.content)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(6)
                                }
                            }
                        }
                    }
                    .navigationTitle("Review Imports")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showingReviewSheet = false }
                        }
                    }
                }
            }
            .overlay {
                if isProcessingImages {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    ProgressView(processingTotal > 0 ? "Processing \(processingCurrent) of \(processingTotal)…" : "Processing…")
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(10)
                }
            }
        }
    }
    
    private func deleteJokes(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredJokes[index])
        }
    }
    
    private func moveJokes(from sourceFolder: JokeFolder, to destinationFolder: JokeFolder?) {
        let jokesInFolder = jokes.filter { $0.folder?.id == sourceFolder.id }
        for joke in jokesInFolder {
            joke.folder = destinationFolder
        }
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to move jokes: \(error)")
        }
    }
    
    private func removeJokesFromFolderAndDelete(_ folder: JokeFolder) {
        let jokesInFolder = jokes.filter { $0.folder?.id == folder.id }
        for joke in jokesInFolder {
            joke.folder = nil
        }
        deleteFolder(folder)
    }
    
    private func deleteFolder(_ folder: JokeFolder) {
        // Move jokes out of the folder (set to nil) before deleting the folder
        let jokesInFolder = jokes.filter { $0.folder?.id == folder.id }
        for joke in jokesInFolder {
            joke.folder = nil
        }
        
        modelContext.delete(folder)
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to delete folder: \(error)")
        }
    }
    
    private func processScannedImages(_ images: [UIImage]) {
        isProcessingImages = true
        Task {
            for image in images {
                do {
                    let text = try await TextRecognitionService.recognizeText(from: image)
                    var extractedJokes = TextRecognitionService.extractJokes(from: text)
                    // Filter out incomplete or invalid jokes
                    extractedJokes = TextRecognitionService.filterValidJokes(extractedJokes)
                    
                    await MainActor.run {
                        for jokeText in extractedJokes {
                            let (title, isValid) = TextRecognitionService.generateTitleFromJoke(jokeText)
                            // Only create joke if it's valid and has a proper title
                            if isValid && !title.isEmpty {
                                let joke = Joke(content: jokeText, title: title, folder: selectedFolder)
                                modelContext.insert(joke)
                                print("✅ SCANNER: Added joke with title: \(title.prefix(40))...")
                            }
                        }
                    }
                } catch {
                    print("Error recognizing text: \(error)")
                }
            }
            await MainActor.run {
                isProcessingImages = false
            }
        }
    }
    
    private func processSelectedPhotos(_ items: [PhotosPickerItem]) async {
        isProcessingImages = true
        processingTotal = items.count
        processingCurrent = 0
        var added = 0
        var skipped = 0
        var candidates: [JokeImportCandidate] = []
        var duplicates: [String] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                do {
                    let text = try await TextRecognitionService.recognizeText(from: image)
                    var extractedJokes = TextRecognitionService.extractJokes(from: text)
                    // Filter out incomplete or invalid jokes
                    extractedJokes = TextRecognitionService.filterValidJokes(extractedJokes)
                    
                    await MainActor.run {
                        for jokeText in extractedJokes {
                            let (title, isValid) = TextRecognitionService.generateTitleFromJoke(jokeText)
                            if isValid && !title.isEmpty {
                                if isLikelyDuplicate(jokeText, title: title) {
                                    duplicates.append("\(title) — duplicate suspected")
                                    skipped += 1
                                } else {
                                    let joke = Joke(content: jokeText, title: title, folder: selectedFolder)
                                    modelContext.insert(joke)
                                    added += 1
                                    print("✅ PHOTOS: Added joke with title: \(title.prefix(40))...")
                                }
                            } else {
                                // Borderline candidate for review
                                let candidate = JokeImportCandidate(
                                    content: jokeText,
                                    suggestedTitle: String(jokeText.prefix(50)),
                                    isComplete: TextRecognitionService.isCompleteJoke(jokeText),
                                    confidence: Double(TextRecognitionService.countSentences(jokeText)) / 3.0,
                                    issues: ["Needs review"],
                                    suggestedFix: nil
                                )
                                candidates.append(candidate)
                                skipped += 1
                            }
                        }
                    }
                } catch {
                    print("Error recognizing text: \(error)")
                }
            }
            await MainActor.run { processingCurrent += 1 }
        }
        await MainActor.run {
            importSummary = (added, skipped)
            showingImportSummary = true
            reviewCandidates = candidates
            possibleDuplicates = duplicates
            if !candidates.isEmpty { showingReviewSheet = true }
            selectedPhotos = []
            isProcessingImages = false
        }
    }
    
    private func processDocuments(_ urls: [URL]) {
        isProcessingImages = true
        Task {
            var totalAdded = 0
            var skipped = 0
            var candidates: [JokeImportCandidate] = []
            var duplicates: [String] = []
            for url in urls {
                // Files picked with asCopy: true are already inside sandbox; no need for security-scoped access.
                let fileExists = FileManager.default.fileExists(atPath: url.path)
                if !fileExists {
                    print("❌ DOCS: File not found: \(url.path)")
                    continue
                }
                let ext = url.pathExtension.lowercased()
                if ext == "pdf" {
                    await processPDF(url: url) { jokes in
                        await MainActor.run {
                            let filteredJokes = TextRecognitionService.filterValidJokes(jokes)
                            for jokeText in filteredJokes {
                                let (title, isValid) = TextRecognitionService.generateTitleFromJoke(jokeText)
                                if isValid && !title.isEmpty {
                                    if isLikelyDuplicate(jokeText, title: title) {
                                        duplicates.append("\(title) — duplicate suspected")
                                        skipped += 1
                                    } else {
                                        let joke = Joke(content: jokeText, title: title, folder: selectedFolder)
                                        modelContext.insert(joke)
                                        totalAdded += 1
                                        print("✅ PDF: Added joke with title: \(title.prefix(40))...")
                                    }
                                } else {
                                    let candidate = JokeImportCandidate(
                                        content: jokeText,
                                        suggestedTitle: String(jokeText.prefix(50)),
                                        isComplete: TextRecognitionService.isCompleteJoke(jokeText),
                                        confidence: Double(TextRecognitionService.countSentences(jokeText)) / 3.0,
                                        issues: ["Needs review"],
                                        suggestedFix: nil
                                    )
                                    candidates.append(candidate)
                                    skipped += 1
                                }
                            }
                        }
                    }
                } else {
                    // Load as image via Data for broader format support (JPEG/PNG/HEIC)
                    if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                        do {
                            let text = try await TextRecognitionService.recognizeText(from: image)
                            var extractedJokes = TextRecognitionService.extractJokes(from: text)
                            // Filter out incomplete or invalid jokes
                            extractedJokes = TextRecognitionService.filterValidJokes(extractedJokes)
                            await MainActor.run {
                                for jokeText in extractedJokes {
                                    let (title, isValid) = TextRecognitionService.generateTitleFromJoke(jokeText)
                                    if isValid && !title.isEmpty {
                                        if isLikelyDuplicate(jokeText, title: title) {
                                            duplicates.append("\(title) — duplicate suspected")
                                            skipped += 1
                                        } else {
                                            let joke = Joke(content: jokeText, title: title, folder: selectedFolder)
                                            modelContext.insert(joke)
                                            totalAdded += 1
                                            print("✅ IMAGE: Added joke with title: \(title.prefix(40))...")
                                        }
                                    } else {
                                        let candidate = JokeImportCandidate(
                                            content: jokeText,
                                            suggestedTitle: String(jokeText.prefix(50)),
                                            isComplete: TextRecognitionService.isCompleteJoke(jokeText),
                                            confidence: Double(TextRecognitionService.countSentences(jokeText)) / 3.0,
                                            issues: ["Needs review"],
                                            suggestedFix: nil
                                        )
                                        candidates.append(candidate)
                                        skipped += 1
                                    }
                                }
                            }
                        } catch {
                            print("❌ DOCS: OCR failed for image \(url.lastPathComponent): \(error)")
                        }
                    } else {
                        print("❌ DOCS: Could not decode image from \(url.lastPathComponent)")
                    }
                }
            }
            await MainActor.run {
                isProcessingImages = false
                importSummary = (totalAdded, skipped)
                showingImportSummary = true
                reviewCandidates = candidates
                possibleDuplicates = duplicates
                if !candidates.isEmpty { showingReviewSheet = true }
                print("🏁 DOCS: Finished. Total jokes added: \(totalAdded)")
            }
        }
    }

    // Stream PDF pages one-by-one to avoid memory spikes; return jokes incrementally
    private func processPDF(url: URL, onPageJokes: @escaping ([String]) async -> Void) async {
        guard let document = CGPDFDocument(url as CFURL) else {
            print("❌ PDF: Failed to load \(url.lastPathComponent)")
            return
        }
        let maxDim: CGFloat = 1800
        let pageCount = document.numberOfPages
        await MainActor.run {
            processingTotal = pageCount
            processingCurrent = 0
        }
        for pageNum in 1...pageCount {
            guard let page = document.page(at: pageNum) else { continue }
            let media = page.getBoxRect(.mediaBox)
            let scale = min(maxDim / max(media.width, media.height), 2.0)
            let renderSize = CGSize(width: media.width * scale, height: media.height * scale)
            let format = UIGraphicsImageRendererFormat.default()
            format.scale = 1.0
            let renderer = UIGraphicsImageRenderer(size: renderSize, format: format)
            let image = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(CGRect(origin: .zero, size: renderSize))
                ctx.cgContext.translateBy(x: 0, y: renderSize.height)
                ctx.cgContext.scaleBy(x: scale, y: -scale)
                ctx.cgContext.drawPDFPage(page)
            }
            do {
                let text = try await TextRecognitionService.recognizeText(from: image)
                let jokes = TextRecognitionService.extractJokes(from: text)
                await onPageJokes(jokes)
            } catch {
                print("❌ PDF: OCR failed on page \(pageNum): \(error)")
            }
            await MainActor.run { processingCurrent += 1 }
            await Task.yield()
        }
    }
    
    private func exportJokesToPDF() {
        let jokesToExport = selectedFolder != nil ? filteredJokes : jokes
        if let url = PDFExportService.exportJokesToPDF(jokes: jokesToExport) {
            exportedPDFURL = url
            showingExportAlert = true
        }
    }
    
    private func shareFile(_ url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func isLikelyDuplicate(_ content: String, title: String?) -> Bool {
        let newKey = content.normalizedPrefix()
        // Check against existing jokes in current filtered set and full list
        if jokes.contains(where: { $0.content.normalizedPrefix() == newKey }) { return true }
        if let title = title, !title.isEmpty {
            let t = title.lowercased().trimmingCharacters(in: .whitespaces)
            if jokes.contains(where: { $0.title.lowercased().trimmingCharacters(in: .whitespaces) == t }) { return true }
        }
        return false
    }
    
    private func checkPendingVoiceMemoImports() {
        let sharedDefaults = UserDefaults(suiteName: "group.com.taylordrew.thebitbinder")
        guard let pendingImports = sharedDefaults?.array(forKey: "pendingVoiceMemoImports") as? [[String: String]],
              !pendingImports.isEmpty else { return }
        
        var importedCount = 0
        for importData in pendingImports {
            guard let transcription = importData["transcription"],
                  !transcription.isEmpty else { continue }
            
            _ = importData["filename"] ?? "Voice Memo"
            let title = AudioTranscriptionService.generateTitle(from: transcription)
            
            // Check for duplicates
            if !isLikelyDuplicate(transcription, title: title) {
                let joke = Joke(content: transcription, title: title, folder: selectedFolder)
                modelContext.insert(joke)
                importedCount += 1
            }
        }
        
        // Clear pending imports
        sharedDefaults?.removeObject(forKey: "pendingVoiceMemoImports")
        sharedDefaults?.synchronize()
        
        if importedCount > 0 {
            try? modelContext.save()
            importSummary = (importedCount, 0)
            showingImportSummary = true
        }
    }
}

private extension JokesView {
    func matchesSearch(_ joke: Joke, lower: String) -> Bool {
        let title = joke.title.lowercased()
        if title.contains(lower) { return true }
        let content = joke.content.lowercased()
        return content.contains(lower)
    }
}

struct FolderChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .medium)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color(UIColor.systemGray6))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct JokeRowView: View {
    let joke: Joke
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(joke.title)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            Text(joke.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            HStack(spacing: 12) {
                if let folder = joke.folder {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.caption2)
                        Text(folder.name)
                            .font(.caption)
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                Text(joke.dateCreated, format: .dateTime.month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 6)
    }
}
