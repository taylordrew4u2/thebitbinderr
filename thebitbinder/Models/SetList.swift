//
//  SetList.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/2/25.
//

import Foundation
import SwiftData

@Model
final class SetList {
    var id: UUID
    var name: String
    var dateCreated: Date
    var dateModified: Date
    var jokeIDs: [UUID]
    
    init(name: String, jokeIDs: [UUID] = []) {
        self.id = UUID()
        self.name = name
        self.dateCreated = Date()
        self.dateModified = Date()
        self.jokeIDs = jokeIDs
    }
}
