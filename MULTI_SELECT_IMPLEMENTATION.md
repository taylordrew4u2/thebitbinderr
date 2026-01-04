# Multi-Select Jokes Feature Implementation Guide

## Overview
This document describes how to add multi-select functionality to JokesView to allow selecting, moving, and deleting multiple jokes at once.

## Changes Required

### 1. Add State Variables (after line 32)
Add these state variables to track selection mode and selected jokes:

```swift
// Multi-select states
@State private var isSelectionMode = false
@State private var selectedJokes: Set<Joke.ID> = []
@State private var showingBulkMoveSheet = false
@State private var showingBulkDeleteAlert = false
```

### 2. Modify Toolbar (around line 152)
Replace the trailing toolbar item to add a "Select" button:

```swift
ToolbarItem(placement: .navigationBarTrailing) {
    if isSelectionMode {
        HStack(spacing: 16) {
            Button("Cancel") {
                isSelectionMode = false
                selectedJokes.removeAll()
            }
            
            if !selectedJokes.isEmpty {
                Menu {
                    Button(action: { showingBulkMoveSheet = true }) {
                        Label("Move to Folder", systemImage: "folder")
                    }
                    
                    Button(role: .destructive, action: { showingBulkDeleteAlert = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    } else {
        Menu {
            Button(action: { isSelectionMode = true }) {
                Label("Select", systemImage: "checkmark.circle")
            }
            
            Divider()
            
            Button(action: { showingAddJoke = true }) {
                Label("Add Manually", systemImage: "square.and.pencil")
            }
            
            Button(action: { showingScanner = true }) {
                Label("Scan from Camera", systemImage: "camera")
            }
            
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
```

### 3. Modify Joke List (around line 120)
Replace the ForEach section to add checkbox selection:

```swift
ForEach(filteredJokes) { joke in
    if isSelectionMode {
        HStack {
            Button(action: {
                if selectedJokes.contains(joke.id) {
                    selectedJokes.remove(joke.id)
                } else {
                    selectedJokes.insert(joke.id)
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: selectedJokes.contains(joke.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selectedJokes.contains(joke.id) ? .blue : .gray)
                        .font(.title3)
                    
                    JokeRowView(joke: joke)
                }
            }
            .buttonStyle(.plain)
        }
    } else {
        NavigationLink(destination: JokeDetailView(joke: joke)) {
            JokeRowView(joke: joke)
        }
    }
}
.onDelete(perform: isSelectionMode ? nil : deleteJokes)
```

### 4. Add Bulk Action Functions (before the closing brace of JokesView struct)
Add these functions to handle bulk operations:

```swift
private func bulkDeleteJokes() {
    let jokesToDelete = filteredJokes.filter { selectedJokes.contains($0.id) }
    for joke in jokesToDelete {
        modelContext.delete(joke)
    }
    selectedJokes.removeAll()
    isSelectionMode = false
}

private func bulkMoveJokes(to folder: JokeFolder?) {
    let jokesToMove = filteredJokes.filter { selectedJokes.contains($0.id) }
    for joke in jokesToMove {
        joke.folder = folder
    }
    selectedJokes.removeAll()
    isSelectionMode = false
}
```

### 5. Add Sheets and Alerts (after existing sheet modifiers, around line 245)
Add these view modifiers for bulk actions:

```swift
.sheet(isPresented: $showingBulkMoveSheet) {
    NavigationStack {
        List {
            Section("Select Folder") {
                Button("Unfiled") {
                    bulkMoveJokes(to: nil)
                    showingBulkMoveSheet = false
                }
                
                ForEach(folders) { folder in
                    Button(folder.name) {
                        bulkMoveJokes(to: folder)
                        showingBulkMoveSheet = false
                    }
                }
            }
        }
        .navigationTitle("Move \(selectedJokes.count) Jokes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    showingBulkMoveSheet = false
                }
            }
        }
    }
    .presentationDetents([.medium])
}
.alert("Delete \(selectedJokes.count) Jokes?", isPresented: $showingBulkDeleteAlert) {
    Button("Cancel", role: .cancel) { }
    Button("Delete", role: .destructive) {
        bulkDeleteJokes()
    }
} message: {
    Text("This action cannot be undone.")
}
```

## User Experience Flow

1. **Enter Selection Mode**: User taps the "+" menu and selects "Select"
2. **Select Jokes**: Checkboxes appear next to each joke. User taps jokes to select/deselect
3. **Bulk Actions**: When jokes are selected, an actions menu (•••) appears with:
   - Move to Folder
   - Delete
4. **Move**: Shows a sheet with list of folders to choose from
5. **Delete**: Shows confirmation alert before deleting
6. **Exit**: Tap "Cancel" to exit selection mode

## Benefits

- **Efficiency**: Move or delete multiple jokes at once instead of one-by-one
- **User-Friendly**: Clear visual feedback with checkboxes
- **Safe**: Confirmation dialog prevents accidental bulk deletion
- **Flexible**: Can select any combination of jokes from filtered view

## Implementation Notes

- Selection is maintained in a `Set<Joke.ID>` for O(1) lookup performance
- Selection mode disables swipe-to-delete to avoid conflicts
- Exiting selection mode automatically clears all selections
- The selected count is displayed in the move sheet title
