//
//  SyllabusImportView.swift
//  Classlly
//
//  Created by Robu Darius on 11.12.2025.
//


import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SyllabusImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isImporterPresented = false
    @State private var isLoading = false
    @State private var showReviewModal = false
    @State private var errorMessage: String?
    
    // Staging area for events before saving
    @State private var extractedEvents: [ClassEvent] = []
    
    private let parser = SyllabusParser()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .padding()
                
                Text("Import Syllabus")
                    .font(.title2.bold())
                
                Text("Upload a PDF syllabus to automatically extract deadlines, exams, and assignments.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                if isLoading {
                    ProgressView("Analyzing with Gemini AI...")
                        .padding()
                } else {
                    Button(action: { isImporterPresented = true }) {
                        Label("Select PDF File", systemImage: "arrow.up.doc")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                }
                
                Spacer()
            }
            .navigationTitle("AI Import")
            // File Importer
            .fileImporter(
                isPresented: $isImporterPresented,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            // Review Modal
            .sheet(isPresented: $showReviewModal) {
                SyllabusReviewView(events: $extractedEvents, onSave: saveEvents)
            }
        }
    }
    
    // MARK: - Logic
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Access security scoped resource if necessary (usually needed for iOS file picker)
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Permission denied to access file."
                isLoading = false
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            Task {
                // 1. Extract Text
                let pdfText = parser.extractText(from: url)
                
                if pdfText.isEmpty {
                    await MainActor.run {
                        errorMessage = "Could not extract text from PDF. It might be an image scan."
                        isLoading = false
                    }
                    return
                }
                
                // 2. Parse with AI
                do {
                    let events = try await parser.parseSyllabus(text: pdfText)
                    
                    await MainActor.run {
                        self.extractedEvents = events
                        self.isLoading = false
                        if !events.isEmpty {
                            self.showReviewModal = true
                        } else {
                            self.errorMessage = "No events were found in the syllabus."
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = "AI Parsing failed: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                }
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    private func saveEvents() {
        // Batch insert into SwiftData context
        for event in extractedEvents {
            modelContext.insert(event)
        }
        
        // Save handled automatically by SwiftData autosave, or force try modelContext.save()
        dismiss()
    }
}

// MARK: - Subview: Review Modal

struct SyllabusReviewView: View {
    @Binding var events: [ClassEvent]
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if events.isEmpty {
                    Text("No events extracted.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach($events) { $event in
                        HStack {
                            VStack(alignment: .leading) {
                                TextField("Title", text: $event.title)
                                    .font(.headline)
                                Text(event.type)
                                    .font(.caption)
                                    .padding(4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            
                            Spacer()
                            
                            DatePicker("Date", selection: $event.date, displayedComponents: .date)
                                .labelsHidden()
                        }
                    }
                    .onDelete { indexSet in
                        events.remove(atOffsets: indexSet)
                    }
                }
            }
            .navigationTitle("Review Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save to Calendar") {
                        onSave()
                    }
                    .disabled(events.isEmpty)
                }
            }
        }
    }
}