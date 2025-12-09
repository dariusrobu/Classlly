//
//  ScheduleImportReviewView.swift
//  Classlly
//
//  Created by Robu Darius on 09.12.2025.
//


import SwiftUI
import SwiftData

struct ScheduleImportReviewView: View {
    // Input: The candidates found by the scanner
    @State var candidates: [ScannedClassCandidate]
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    // Alert state for completion
    @State private var showingSuccessAlert = false
    @State private var importedCount = 0

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Detected Classes")) {
                    if candidates.isEmpty {
                        Text("No classes detected. Try scanning again with better lighting.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach($candidates) { $candidate in
                            CandidateRow(candidate: $candidate)
                        }
                    }
                }
            }
            .navigationTitle("Review Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import Selected") {
                        importSelectedClasses()
                    }
                    .fontWeight(.bold)
                    .disabled(candidates.filter { $0.isSelected }.isEmpty)
                }
            }
            .alert("Import Complete", isPresented: $showingSuccessAlert) {
                Button("Done") { dismiss() }
            } message: {
                Text("Successfully imported \(importedCount) subjects into your schedule.")
            }
        }
    }
    
    // MARK: - SwiftData Conversion Logic
    private func importSelectedClasses() {
        let selectedCandidates = candidates.filter { $0.isSelected }
        
        for candidate in selectedCandidates {
            // NOTE: In a production app, you would parse candidate.detectedTime into a real Date object.
            // For now, we use defaults as requested.
            
            let newSubject = Subject(
                title: candidate.detectedTitle,
                courseTeacher: "", // OCR didn't detect this specifically
                courseClassroom: "", // User can add this later
                courseDate: Date(),
                courseStartTime: Date(), // Placeholder: Add logic to parse candidate.detectedTime
                courseEndTime: Date().addingTimeInterval(5400), // Defaulting to 1.5 hours duration
                courseDays: [], // Placeholder: Needs day parsing logic
                seminarTeacher: "",
                seminarClassroom: ""
            )
            
            modelContext.insert(newSubject)
        }
        
        // Save Context
        do {
            try modelContext.save()
            importedCount = selectedCandidates.count
            showingSuccessAlert = true
        } catch {
            print("Failed to import subjects: \(error)")
        }
    }
}

// MARK: - Helper Row View
struct CandidateRow: View {
    @Binding var candidate: ScannedClassCandidate
    
    var body: some View {
        HStack(spacing: 12) {
            // 1. Toggle Selection
            Toggle(isOn: $candidate.isSelected) {
                EmptyView()
            }
            .labelsHidden()
            .tint(.blue)
            
            // 2. Editable Fields
            VStack(alignment: .leading, spacing: 4) {
                TextField("Class Name", text: $candidate.detectedTitle)
                    .font(.headline)
                    .foregroundColor(candidate.isSelected ? .primary : .secondary)
                
                TextField("Time", text: $candidate.detectedTime)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .opacity(candidate.isSelected ? 1.0 : 0.5) // visually dim unselected items
        }
        .padding(.vertical, 4)
    }
}