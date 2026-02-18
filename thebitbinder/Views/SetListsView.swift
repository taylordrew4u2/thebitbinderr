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
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple.opacity(0.12), Color.purple.opacity(0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            Image(systemName: "list.bullet.clipboard.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .purple.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(spacing: 8) {
                            Text("No set lists yet")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Create your first set list using the + button")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 40)
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
    
    private let accentColor = Color(red: 0.7, green: 0.4, blue: 1.0)
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.15), accentColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)
                
                Image(systemName: "list.bullet.rectangle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(setList.name)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                
                HStack(spacing: 14) {
                    HStack(spacing: 4) {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 11))
                        Text("\(setList.jokeIDs.count) jokes")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(accentColor.opacity(0.9))
                    
                    Text(setList.dateModified, format: .dateTime.month(.abbreviated).day())
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.quaternary)
        }
        .padding(.vertical, 8)
    }
}
