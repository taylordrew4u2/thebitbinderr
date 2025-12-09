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
    @State private var folderPendingDeletion: JokeFolder?
    @State private var showingDeleteFolderAlert = false
    @State private var showingMoveJokesSheet = false

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
        VStack(spacing: 20) {
            Image(systemName: "text.bubble")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No jokes yet")
                .font(.title2)
                .foregroundColor(.gray)
            Text("Add your first joke using the + button")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        if trimmed.isEmpty {
            return base
        }
        let lower = trimmed.lowercased()
        return base.filter { matchesSearch($0, lower: lower) }
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
                        
                        Button(action: { showingScanner = true }) {
                            Label("Scan from Camera", systemImage: "camera")
                        }
                        
                        // Replaced inline PhotosPicker with a button that triggers .photosPicker modifier
                        Button(action: { showingImagePicker = true }) {
                            Label("Import Photos", systemImage: "photo.on.rectangle")
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
            .overlay {
                if isProcessingImages {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    ProgressView("Processing images...")
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
                            // Only create joke if it's valid and has a proper title
                            if isValid && !title.isEmpty {
                                let joke = Joke(content: jokeText, title: title, folder: selectedFolder)
                                modelContext.insert(joke)
                                print("✅ PHOTOS: Added joke with title: \(title.prefix(40))...")
                            }
                        }
                    }
                } catch {
                    print("Error recognizing text: \(error)")
                }
            }
        }
        await MainActor.run {
            selectedPhotos = []
            isProcessingImages = false
        }
    }
    
    private func processDocuments(_ urls: [URL]) {
        isProcessingImages = true
        Task {
            var totalAdded = 0
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
                                // Only create joke if it's valid and has a proper title
                                if isValid && !title.isEmpty {
                                    let joke = Joke(content: jokeText, title: title, folder: selectedFolder)
                                    modelContext.insert(joke)
                                    totalAdded += 1
                                    print("✅ PDF: Added joke with title: \(title.prefix(40))...")
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
                                    // Only create joke if it's valid and has a proper title
                                    if isValid && !title.isEmpty {
                                        let joke = Joke(content: jokeText, title: title, folder: selectedFolder)
                                        modelContext.insert(joke)
                                        totalAdded += 1
                                        print("✅ IMAGE: Added joke with title: \(title.prefix(40))...")
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
        let maxDim: CGFloat = 1600
        let pageCount = document.numberOfPages
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
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(UIColor.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct JokeRowView: View {
    let joke: Joke
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(joke.title)
                .font(.headline)
            Text(joke.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            HStack {
                if let folder = joke.folder {
                    Label(folder.name, systemImage: "folder")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                Spacer()
                Text(joke.dateCreated, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

