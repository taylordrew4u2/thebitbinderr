//
//  CreateSetListView.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/2/25.
//

import SwiftUI
import SwiftData

struct CreateSetListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Set List Name")) {
                    TextField("Enter set list name", text: $name)
                }
            }
            .navigationTitle("New Set List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createSetList()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func createSetList() {
        let setList = SetList(name: name)
        modelContext.insert(setList)
        dismiss()
    }
}
