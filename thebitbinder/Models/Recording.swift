//
//  Recording.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/2/25.
//

import Foundation
import SwiftData

@Model
final class Recording {
    var id: UUID
    var name: String
    var dateCreated: Date
    var duration: TimeInterval
    var fileURL: String
    var setListID: UUID?
    var transcription: String?
    
    init(name: String, fileURL: String, duration: TimeInterval = 0, setListID: UUID? = nil) {
        self.id = UUID()
        self.name = name
        self.dateCreated = Date()
        self.duration = duration
        self.fileURL = fileURL
        self.setListID = setListID
        self.transcription = nil
    }
}
