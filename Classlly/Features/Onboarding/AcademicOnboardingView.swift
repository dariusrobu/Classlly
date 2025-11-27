import SwiftUI

struct AcademicOnboardingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedTemplateID: UUID?
    @State private var showingManualEntry = false
    
    // Manual entry fields
    @State private var sem1Start = Date()
    @State private var sem1End = Date()
    @State private var sem2Start = Date()
    @State private var sem2End = Date()
    @State private var academicYear: String = "2025-2026"
    @State private var schoolName: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Confirm Your School")) {
                    Picker("Select Your School", selection: $selectedTemplateID) {
                        Text("Select a school...").tag(nil as UUID?)
                        ForEach(calendarManager.availableTemplates) { template in
                            Text(template.universityName).tag(template.id as UUID?)
                        }
                        Text("My school isn't listed...").tag(UUID.init())
                    }
                    .onChange(of: selectedTemplateID) { oldValue, newValue in
                        // Check if user selected "My school isn't listed" or a valid template
                        if let id = newValue {
                            if calendarManager.availableTemplates.first(where: { $0.id == id }) == nil {
                                self.showingManualEntry = true
                            } else {
                                self.showingManualEntry = false
                            }
                        } else {
                            self.showingManualEntry = false
                        }
                    }
                }
                .listRowBackground(Color.themeSurface)
                
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
                
                Section {
                    Button(action: setupCalendar) {
                        HStack {
                            Spacer()
                            Text("Get Started").font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(selectedTemplateID == nil)
                }
                .listRowBackground(Color.themeSurface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground)
            .navigationTitle("Setup Your Calendar")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Safe lookup logic moved here
                let template = calendarManager.availableTemplates.first {
                    $0.universityName == authManager.universityNameForOnboarding
                }
                
                if let match = template {
                    self.selectedTemplateID = match.id
                    self.schoolName = match.universityName
                    self.academicYear = match.academicYear
                } else if !authManager.universityNameForOnboarding.isEmpty {
                    self.schoolName = authManager.universityNameForOnboarding
                }
            }
        }
        .preferredColorScheme(colorScheme)
    }
    
    func setupCalendar() {
        if showingManualEntry {
            calendarManager.generateAndSaveCustomCalendar(
                year: academicYear,
                universityName: schoolName.isEmpty ? "My University" : schoolName,
                sem1Start: sem1Start,
                sem1End: sem1End,
                sem2Start: sem2Start,
                sem2End: sem2End
            )
        } else if let template = calendarManager.availableTemplates.first(where: { $0.id == selectedTemplateID }) {
            calendarManager.generateAndSaveCalendar(from: template)
        }
        
        // Close the onboarding flow (handled by parent view watching authManager state)
        authManager.requiresOnboarding = false
    }
}
