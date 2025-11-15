//
//  AcademicOnboardingView.swift
//  Classlly
//
//  Created by Robu Darius on 14.11.2025.
//


// File: Classlly/Auth/AcademicOnboardingView.swift
// Note: This view is presented to new users to set up their
// academic calendar, either from a template or manually.

import SwiftUI

struct AcademicOnboardingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @Environment(\.colorScheme) var colorScheme
    
    // --- UPDATED STATE ---
    @State private var selectedTemplateID: UUID?
    @State private var showingManualEntry = false
    
    // Manual entry fields
    @State private var sem1Start = Date()
    @State private var sem1End = Date()
    @State private var sem2Start = Date()
    @State private var sem2End = Date()
    @State private var academicYear: String = "2025-2026"
    @State private var schoolName: String = ""
    // --- END UPDATED STATE ---

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    // This is the template we found, if any
    private var matchedTemplate: CalendarTemplate? {
        calendarManager.availableTemplates.first { $0.universityName == authManager.universityNameForOnboarding }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // --- NEW: Template Picker ---
                Section(header: Text("Confirm Your School")) {
                    Picker("Select Your School", selection: $selectedTemplateID) {
                        Text("Select a school...").tag(nil as UUID?)
                        ForEach(calendarManager.availableTemplates) { template in
                            Text(template.universityName).tag(template.id as UUID?)
                        }
                        Text("My school isn't listed...").tag(UUID.init()) // A dummy ID for "Other"
                    }
                    .onChange(of: selectedTemplateID) { oldValue, newValue in
                        if newValue != nil && newValue != matchedTemplate?.id {
                            // If user selected "My school isn't listed"
                            if calendarManager.availableTemplates.first(where: { $0.id == newValue }) == nil {
                                self.showingManualEntry = true
                            }
                        } else {
                            self.showingManualEntry = false
                        }
                    }
                }
                .listRowBackground(Color.themeSurface)
                // --- END NEW ---
                
                // --- NEW: Manual Entry (hidden by default) ---
                if showingManualEntry {
                    Section(header: Text("Manual Setup")) {
                        TextField("Academic Year (e.g., 2025-2026)", text: $academicYear)
                        TextField("University Name", text: $schoolName)
                    }
                    .listRowBackground(Color.themeSurface)

                    Section(header: Text("Semester 1")) {
                        DatePicker("First Day of Class", selection: $sem1Start, displayedComponents: .date)
                        DatePicker("Last Day of Class", selection: $sem1End, displayedComponents: .date)
                    }
                    .listRowBackground(Color.themeSurface)

                    Section(header: Text("Semester 2")) {
                        DatePicker("First Day of Class", selection: $sem2Start, displayedComponents: .date)
                        DatePicker("Last Day of Class", selection: $sem2End, displayedComponents: .date)
                    }
                    .listRowBackground(Color.themeSurface)
                }
                // --- END NEW ---
                
                Section {
                    Button(action: setupCalendar) {
                        HStack {
                            Spacer()
                            Text("Get Started")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(selectedTemplateID == nil) // Disable button until a choice is made
                }
                .listRowBackground(Color.themeSurface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground)
            .navigationTitle("Setup Your Calendar")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Pre-select the school if we have a match from the profile
                if let template = matchedTemplate {
                    self.selectedTemplateID = template.id
                    self.schoolName = template.universityName
                    self.academicYear = template.academicYear
                }
                // If school name was provided but didn't match, pre-fill it for manual entry
                else if !authManager.universityNameForOnboarding.isEmpty {
                    self.schoolName = authManager.universityNameForOnboarding
                }
            }
        }
        .preferredColorScheme(colorScheme)
    }
    
    func setupCalendar() {
        // --- UPDATED LOGIC ---
        if showingManualEntry {
            // 1. User is using Manual Setup
            calendarManager.generateAndSaveCustomCalendar(
                year: academicYear,
                universityName: schoolName.isEmpty ? "My University" : schoolName,
                sem1Start: sem1Start,
                sem1End: sem1End,
                sem2Start: sem2Start,
                sem2End: sem2End
            )
        } else if let template = calendarManager.availableTemplates.first(where: { $0.id == selectedTemplateID }) {
            // 2. User selected a Template
            calendarManager.generateAndSaveCalendar(from: template)
        }
        
        // 3. Mark onboarding as complete and dismiss
        self.hasCompletedOnboarding = true
        authManager.requiresOnboarding = false
    }
}