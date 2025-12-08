//
//  HelpView.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/6/25.
//

import SwiftUI

struct HelpView: View {
    @State private var searchText = ""
    
    var searchResults: [(section: HelpSection, items: [HelpItem])] {
        if searchText.isEmpty {
            return HelpSection.allSections.map { ($0, $0.items) }
        }
        
        let lowercased = searchText.lowercased()
        var results: [(section: HelpSection, items: [HelpItem])] = []
        
        for section in HelpSection.allSections {
            let matchingItems = section.items.filter { item in
                item.question.lowercased().contains(lowercased) ||
                (item.symptoms?.contains { $0.lowercased().contains(lowercased) } ?? false) ||
                item.solutions.contains { $0.lowercased().contains(lowercased) } ||
                (item.tips?.contains { $0.lowercased().contains(lowercased) } ?? false)
            }
            
            if !matchingItems.isEmpty || section.title.lowercased().contains(lowercased) {
                results.append((section, matchingItems.isEmpty ? section.items : matchingItems))
            }
        }
        
        return results
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if searchResults.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No results found")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Try different search terms")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(searchResults, id: \.section.id) { result in
                            Section {
                                ForEach(result.items) { item in
                                    NavigationLink(destination: HelpItemDetailView(item: item, sectionTitle: result.section.title)) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.question)
                                                .font(.headline)
                                        }
                                    }
                                }
                            } header: {
                                HStack {
                                    Image(systemName: result.section.icon)
                                    Text(result.section.title)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Help & Troubleshooting")
            .searchable(text: $searchText, prompt: "Search help topics")
        }
    }
}

struct HelpItemDetailView: View {
    let item: HelpItem
    let sectionTitle: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(sectionTitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Text(item.question)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                if let symptoms = item.symptoms, !symptoms.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Symptoms", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        ForEach(symptoms, id: \.self) { symptom in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.orange)
                                    .padding(.top, 6)
                                Text(symptom)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Label("Solutions", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    ForEach(Array(item.solutions.enumerated()), id: \.offset) { index, solution in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.headline)
                                .foregroundColor(.green)
                                .frame(width: 24, height: 24)
                                .background(Color.green.opacity(0.2))
                                .clipShape(Circle())
                            Text(solution)
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                
                if let tips = item.tips, !tips.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Pro Tips", systemImage: "lightbulb.fill")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        ForEach(tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 14))
                                Text(tip)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Data Models

struct HelpSection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let items: [HelpItem]
    
    static let allSections: [HelpSection] = [
        .importIssues,
        .performance,
        .scannerIssues,
        .photosIssues,
        .fileIssues,
        .quickReference
    ]
}

struct HelpItem: Identifiable {
    let id = UUID()
    let question: String
    let symptoms: [String]?
    let solutions: [String]
    let tips: [String]?
}

// MARK: - Help Content

extension HelpSection {
    static let importIssues = HelpSection(
        title: "Jokes Not Being Imported",
        icon: "exclamationmark.triangle",
        items: [
            HelpItem(
                question: "No jokes appear after importing",
                symptoms: [
                    "Progress indicator disappears but nothing happens",
                    "Empty results from OCR",
                    "Import button does nothing"
                ],
                solutions: [
                    "Ensure images are clear and well-lit",
                    "Use high contrast (dark text on light background)",
                    "Avoid blurry or low-resolution images",
                    "Recommended: 300 DPI or higher for scanned documents",
                    "Verify supported file formats: JPEG, PNG, HEIC, PDF"
                ],
                tips: [
                    "Test with a simple screenshot of text first",
                    "Try smaller batches (5-10 items at a time)"
                ]
            )
        ]
    )
    
    static let performance = HelpSection(
        title: "App Performance Issues",
        icon: "gauge",
        items: [
            HelpItem(
                question: "App freezes or becomes slow",
                symptoms: [
                    "Processing never completes",
                    "App becomes unresponsive",
                    "Device overheats"
                ],
                solutions: [
                    "Close other apps to free memory",
                    "Restart the app if unresponsive",
                    "Import smaller batches (5-10 items)",
                    "Ensure at least 1GB free storage",
                    "Restart device if persistent"
                ],
                tips: [
                    "Force quit: Swipe up from app switcher",
                    "Restart device if issues persist"
                ]
            )
        ]
    )
    
    static let scannerIssues = HelpSection(
        title: "Camera Scanner Issues",
        icon: "camera",
        items: [
            HelpItem(
                question: "Camera won't open or scans are poor quality",
                symptoms: [
                    "Black screen when scanning",
                    "Scans too dark or light",
                    "Can't capture clear images"
                ],
                solutions: [
                    "Enable camera permission: Settings → thebitbinder → Camera",
                    "Use good lighting (natural light best)",
                    "Hold device steady",
                    "Frame entire page in view",
                    "Use flat surface (not handheld documents)"
                ],
                tips: [
                    "Alternative: Take photo in Camera app, then import",
                    "Avoid flash on glossy paper (causes glare)",
                    "Restart app after enabling permissions"
                ]
            )
        ]
    )
    
    static let photosIssues = HelpSection(
        title: "Photos Import Issues",
        icon: "photo",
        items: [
            HelpItem(
                question: "Can't select or load photos",
                symptoms: [
                    "Photos grayed out",
                    "Processing shows but nothing happens",
                    "Permission denied"
                ],
                solutions: [
                    "Settings → thebitbinder → Photos",
                    "Select 'Full Access' or add specific photos",
                    "Wait for iCloud photos to download first",
                    "Use 'Download and Keep Originals' in Photos settings"
                ],
                tips: [
                    "iCloud photos need to download before import",
                    "Check for cloud download icon in Photos app"
                ]
            )
        ]
    )
    
    static let fileIssues = HelpSection(
        title: "File Picker Issues",
        icon: "folder",
        items: [
            HelpItem(
                question: "Can't access files or 'File not found' errors",
                symptoms: [
                    "Import button does nothing",
                    "Files appear grayed out",
                    "Permission errors"
                ],
                solutions: [
                    "Check app permissions: Settings → thebitbinder → Files",
                    "Enable 'Full Access' for file locations",
                    "Copy file to 'On My iPhone' location first",
                    "Verify file isn't in Recently Deleted"
                ],
                tips: [
                    "Files are copied to app sandbox during import",
                    "Original files remain unchanged"
                ]
            )
        ]
    )
    
    static let quickReference = HelpSection(
        title: "Quick Reference",
        icon: "list.star",
        items: [
            HelpItem(
                question: "Quick troubleshooting checklist",
                symptoms: nil,
                solutions: [
                    "Check device storage (need 1GB+ free)",
                    "Verify app permissions (Photos, Camera, Files)",
                    "Close other apps to free memory",
                    "Select target folder before import",
                    "Don't switch apps while processing",
                    "Wait for processing to complete",
                    "Check 'All Jokes' folder first after import",
                    "Search for keywords if jokes seem missing"
                ],
                tips: [
                    "Most issues resolve with app restart",
                    "Test with simple content first"
                ]
            )
        ]
    )
}

#Preview {
    HelpView()
}
