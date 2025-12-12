import SwiftData
import Foundation

@Model
final class NotebookPhoto {
    var fileURL: URL
    var date: Date
    var caption: String?
    
    init(fileURL: URL, date: Date = Date(), caption: String? = nil) {
        self.fileURL = fileURL
        self.date = date
        self.caption = caption
    }
    
    // Returns the filename from the fileURL
    var filename: String {
        fileURL.lastPathComponent
    }
    
    // Returns true if the file exists at fileURL
    var fileExists: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    // Returns the file size in bytes, or nil if unavailable
    var fileSize: Int? {
        try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int
    }
}
