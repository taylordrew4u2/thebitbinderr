import SwiftUI
import PhotosUI
import SwiftData
import AVFoundation

@Model
final class NotebookPhoto {
    @Attribute(.unique) var id: UUID
    var filename: String
    var caption: String = ""
    
    init(id: UUID = UUID(), filename: String, caption: String = "") {
        self.id = id
        self.filename = filename
        self.caption = caption
    }
    
    var imageURL: URL {
        FileManager.documentsDirectory.appendingPathComponent(filename)
    }
}

extension FileManager {
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

struct NotebookView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var photos: [NotebookPhoto]
    
    @State private var showingDetail: NotebookPhoto?
    @State private var showingImagePicker = false
    @State private var pickedPhotoItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var cameraImage: UIImage?
    
    let columns = [GridItem(.adaptive(minimum: 100), spacing: 16)]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(photos, id: \.id) { photo in
                        if let uiImage = UIImage(contentsOfFile: photo.imageURL.path) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(minWidth: 100, minHeight: 100)
                                .clipped()
                                .cornerRadius(8)
                                .onTapGesture {
                                    showingDetail = photo
                                }
                        } else {
                            Color.gray
                                .frame(minWidth: 100, minHeight: 100)
                                .cornerRadius(8)
                                .overlay(Text("No Image").foregroundColor(.white))
                                .onTapGesture {
                                    showingDetail = photo
                                }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Notebook")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    PhotosPicker(selection: $pickedPhotoItem,
                                 matching: .images,
                                 photoLibrary: .shared()) {
                        Label("Add Photo", systemImage: "photo.on.rectangle")
                    }
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Camera", systemImage: "camera")
                    }
                }
            }
            .onChange(of: pickedPhotoItem) { newItem in
                Task {
                    if let item = newItem {
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
                let newPhoto = NotebookPhoto(filename: filename)
                await MainActor.run {
                    modelContext.insert(newPhoto)
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
                let newPhoto = NotebookPhoto(filename: filename)
                await MainActor.run {
                    modelContext.insert(newPhoto)
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

struct NotebookDetailView: View {
    @Bindable var photo: NotebookPhoto
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let uiImage = UIImage(contentsOfFile: photo.imageURL.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .padding()
                } else {
                    Color.gray
                        .frame(height: 200)
                        .cornerRadius(12)
                        .overlay(Text("Image not found").foregroundColor(.white))
                        .padding()
                }
                TextField("Caption", text: $photo.caption)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Detail")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - CameraView (UIKit wrapped)

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // no update needed
    }
    
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
