//
//  SetListsView.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/2/25.
//

import SwiftUI
import SwiftData

struct SetListsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var setLists: [SetList]
    
    @State private var showingCreateSetList = false
    @State private var searchText = ""
    
    var filteredSetLists: [SetList] {
        if searchText.isEmpty {
            return setLists.sorted { $0.dateModified > $1.dateModified }
        } else {
            return setLists.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.dateModified > $1.dateModified }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if filteredSetLists.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No set lists yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Create your first set list using the + button")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(filteredSetLists) { setList in
                            NavigationLink(value: setList) {
                                SetListRowView(setList: setList)
                            }
                        }
                        .onDelete(perform: deleteSetLists)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Set Lists")
            .navigationDestination(for: SetList.self) { setList in
                SetListDetailView(setList: setList)
            }
            .searchable(text: $searchText, prompt: "Search set lists")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateSetList = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSetList) {
                CreateSetListView()
            }
        }
    }
    
    private func deleteSetLists(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredSetLists[index])
        }
    }
}

struct SetListRowView: View {
    let setList: SetList
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(setList.name)
                .font(.headline)
            HStack {
                Label("\(setList.jokeIDs.count) jokes", systemImage: "text.bubble")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(setList.dateModified, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
