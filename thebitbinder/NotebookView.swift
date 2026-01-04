import SwiftUI
import PhotosUI
import SwiftData
import AVFoundation

extension FileManager {
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

struct NotebookView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var photos: [NotebookPhotoRecord]
    
    @State private var showingDetail: NotebookPhotoRecord?
    @State private var showingImagePicker = false
    @State private var pickedPhotoItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var cameraImage: UIImage?
    
    private func delete(_ photo: NotebookPhotoRecord) {
        let url = FileManager.documentsDirectory.appendingPathComponent(photo.fileURL)
        try? FileManager.default.removeItem(at: url)
        modelContext.delete(photo)
        try? modelContext.save()
    }
    
    let columns = [GridItem(.adaptive(minimum: 110), spacing: 12)]
    
    var body: some View {
        NavigationStack {
            Group {
                if photos.isEmpty {
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 100, height: 100)
                            Image(systemName: "photo.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.blue)
                        }
                        
                        VStack(spacing: 8) {
                            Text("No photos yet")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Add photos of your notes and ideas")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(photos, id: \.id) { photo in
                                let imageURL = FileManager.documentsDirectory.appendingPathComponent(photo.fileURL)
                                PhotoGridItem(imageURL: imageURL) {
                                    showingDetail = photo
                                } onDelete: {
                                    delete(photo)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Photos")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    PhotosPicker(selection: $pickedPhotoItem,
                                 matching: .images,
                                 photoLibrary: .shared()) {
                        Image(systemName: "photo.badge.plus")
                    }
                    Button {
                        showingCamera = true
                    } label: {
                        Image(systemName: "camera")
                    }
                }
            }
            .onChange(of: pickedPhotoItem) { oldValue, newValue in
                Task {
                    if let item = newValue {
                        await importPhoto(from: item)
                        pickedPhotoItem = nil
                    }
                }
            }
            .sheet(isPresented: $showingCamera, onDismiss: {
                if let cameraImage {
                    Task {
                        await saveCameraImage(cameraImage)
                    }
                    self.cameraImage = nil
                }
            }) {
                CameraView(image: $cameraImage)
            }
            .sheet(item: $showingDetail) { photo in
                NotebookDetailView(photo: photo)
                    .environment(\.modelContext, modelContext)
            }
        }
    }
    
    private func importPhoto(from item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }
            guard let uiImage = UIImage(data: data) else { return }
            
            let filename = uniqueFilename() + ".jpg"
            let url = FileManager.documentsDirectory.appendingPathComponent(filename)
            if let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                try jpegData.write(to: url, options: .atomic)
                let newPhoto = NotebookPhotoRecord(caption: "", fileURL: filename)
                await MainActor.run {
                    modelContext.insert(newPhoto)
                    try? modelContext.save()
                }
            }
        } catch {
            // ignore errors silently for now
        }
    }
    
    private func saveCameraImage(_ image: UIImage) async {
        let filename = uniqueFilename() + ".jpg"
        let url = FileManager.documentsDirectory.appendingPathComponent(filename)
        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            do {
                try jpegData.write(to: url, options: .atomic)
                let newPhoto = NotebookPhotoRecord(caption: "", fileURL: filename)
                await MainActor.run {
                    modelContext.insert(newPhoto)
                    try? modelContext.save()
                }
            } catch {
                // ignore errors silently for now
            }
        }
    }
    
    private func uniqueFilename() -> String {
        UUID().uuidString
    }
}

// MARK: - Photo Grid Item

struct PhotoGridItem: View {
    let imageURL: URL
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        CachedImageView(
            fileURL: imageURL,
            placeholder: AnyView(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemGray5))
                    .overlay(
                        ProgressView()
                    )
            ),
            contentMode: .fill,
            cornerRadius: 12
        )
        .frame(minWidth: 110, minHeight: 110)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onTapGesture(perform: onTap)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Detail View

struct NotebookDetailView: View {
    @Bindable var photo: NotebookPhotoRecord
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    private func deleteCurrent() {
        let url = FileManager.documentsDirectory.appendingPathComponent(photo.fileURL)
        try? FileManager.default.removeItem(at: url)
        modelContext.delete(photo)
        try? modelContext.save()
        dismiss()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    let imageURL = FileManager.documentsDirectory.appendingPathComponent(photo.fileURL)
                    if let uiImage = UIImage(contentsOfFile: imageURL.path) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            .padding(.horizontal)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.systemGray5))
                            .frame(height: 250)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                    Text("Image not found")
                                        .font(.caption)
                                }
                                .foregroundStyle(.secondary)
                            )
                            .padding(.horizontal)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Caption")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Add a caption...", text: $photo.caption, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .destructive) {
                        deleteCurrent()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        
        init(parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }
    }
}
