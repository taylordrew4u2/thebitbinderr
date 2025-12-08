//
//  Joke.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/2/25.
//

import Foundation
import SwiftData

@Model
final class Joke {
    var id: UUID
    var content: String
    var title: String
    var dateCreated: Date
    var dateModified: Date
    var folder: JokeFolder?
    
    init(content: String, title: String = "", folder: JokeFolder? = nil) {
        self.id = UUID()
        self.content = content
        self.title = title.isEmpty ? "Untitled Joke" : title
        self.dateCreated = Date()
        self.dateModified = Date()
        self.folder = folder
    }
}
