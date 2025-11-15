//
//  ProfileSetupView.swift
//  Classlly
//
//  Created by Robu Darius on 14.11.2025.
//


// File: Classlly/Auth/ProfileSetupView.swift
// Note: This view is shown after a new user signs in with Apple
// to collect necessary academic profile information.

import SwiftUI

struct ProfileSetupView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    let user: UserProfile
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var schoolName: String = ""
    @State private var educationLevel: String = ""
    @State private var major: String = ""
    @State private var academicYear: String = ""
    
    // Updated options for education levels
    private let educationLevels = ["High School", "Bachelor's Degree", "Master's Degree", "PhD", "Other"]
    private let academicYears = ["2023-2024", "2024-2025", "2025-2026", "2026-2027", "2027-2028"]
    private let popularMajors = [
        "Computer Science", "Engineering", "Business", "Medicine", "Law",
        "Psychology", "Biology", "Chemistry", "Physics", "Mathematics",
        "Economics", "Political Science", "History", "English", "Art",
        "Music", "Architecture", "Education", "Nursing", "Other"
    ]
    
    init(user: UserProfile) {
        self.user = user
        _firstName = State(initialValue: user.firstName)
        _lastName = State(initialValue: user.lastName)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Personal Information Section
                Section(header: Text("Personal Information")) {
                    HStack {
                        TextField("First Name", text: $firstName)
                        TextField("Last Name", text: $lastName)
                    }
                }
                
                // Academic Information Section
                Section(header: Text("Academic Information")) {
                    TextField("School/University Name", text: $schoolName)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Education Level", selection: $educationLevel) {
                        Text("Select Education Level").tag("")
                        ForEach(educationLevels, id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }
                    
                    Picker("Major/Field of Study", selection: $major) {
                        Text("Select Major").tag("")
                        ForEach(popularMajors, id: \.self) { major in
                            Text(major).tag(major)
                        }
                    }
                    
                    Picker("Academic Year", selection: $academicYear) {
                        Text("Select Academic Year").tag("")
                        ForEach(academicYears, id: \.self) { year in
                            Text(year).tag(year)
                        }
                    }
                }
                
                // Additional Information Section (Optional)
                Section(header: Text("Additional Information (Optional)"), footer: Text("This information helps us personalize your experience and provide relevant features.")) {
                    NavigationLink("Add More Details") {
                        AdditionalDetailsView()
                    }
                }
                
                // Terms Agreement
                Section(footer: Text("By completing your profile, you agree to our Terms of Service and Privacy Policy")) {
                    EmptyView()
                }
            }
            .navigationTitle("Complete Your Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        authManager.signOut()
                        dismiss()
                    }
                    .foregroundColor(.themeError)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Continue") {
                        completeProfile()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !schoolName.isEmpty &&
        !educationLevel.isEmpty &&
        !academicYear.isEmpty
    }
    
    private func completeProfile() {
        let completedProfile = UserProfile(
            id: user.id,
            firstName: firstName,
            lastName: lastName,
            email: user.email,
            schoolName: schoolName,
            gradeLevel: educationLevel, // Using educationLevel instead of gradeLevel
            major: major.isEmpty ? nil : major,
            academicYear: academicYear,
            profileImageData: nil
        )
        
        authManager.completeProfileSetup(profile: completedProfile)
        dismiss()
    }
}

struct AdditionalDetailsView: View {
    @State private var studentID = ""
    @State private var expectedGraduation = ""
    @State private var gpa = ""
    @State private var campusLocation = ""
    @State private var learningStyle = ""
    @State private var studyPreferences = ""
    
    private let learningStyles = ["Visual", "Auditory", "Kinesthetic", "Reading/Writing", "Mixed"]
    private let studyPreferencesList = ["Morning", "Afternoon", "Evening", "Night", "Flexible"]
    
    var body: some View {
        Form {
            Section(header: Text("Student Details")) {
                TextField("Student ID (Optional)", text: $studentID)
                    .keyboardType(.numbersAndPunctuation)
                
                TextField("Expected Graduation Year", text: $expectedGraduation)
                    .keyboardType(.numberPad)
                
                TextField("Current GPA (Optional)", text: $gpa)
                    .keyboardType(.decimalPad)
                
                TextField("Campus Location", text: $campusLocation)
            }
            
            Section(header: Text("Learning Preferences")) {
                Picker("Learning Style", selection: $learningStyle) {
                    Text("Select Learning Style").tag("")
                    ForEach(learningStyles, id: \.self) { style in
                        Text(style).tag(style)
                    }
                }
                
                Picker("Preferred Study Time", selection: $studyPreferences) {
                    Text("Select Study Time").tag("")
                    ForEach(studyPreferencesList, id: \.self) { preference in
                        Text(preference).tag(preference)
                    }
                }
            }
            
            Section(footer: Text("These details help us customize your study recommendations and schedule optimizations.")) {
                EmptyView()
            }
        }
        .navigationTitle("Additional Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}