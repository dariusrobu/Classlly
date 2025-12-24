import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                RainbowProfileView()
            case .standard:
                StandardProfileView()
            }
        }
    }
}

// MARK: - 🌈 RAINBOW PROFILE (Editable)
struct RainbowProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: AppTheme
    @Environment(AuthenticationManager.self) private var authManager
    
    @Query private var profiles: [StudentProfile]
    @Query private var appUsers: [AppUser]
    
    // Local Editing State
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var university: String = ""
    @State private var major: String = ""
    @State private var academicYear: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    var currentProfile: StudentProfile? {
        guard let uid = authManager.userSession?.uid else { return profiles.first }
        return profiles.first(where: { $0.id == uid }) ?? profiles.first
    }
    
    var body: some View {
        let accent = themeManager.selectedTheme.primaryColor
        
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            RadialGradient(colors: [accent.opacity(0.2), .black], center: .top, startRadius: 0, endRadius: 600).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("EDIT PROFILE").font(.headline).fontWeight(.black).foregroundColor(.white).tracking(1)
                    Spacer()
                    // Hidden spacer for balance
                    Image(systemName: "chevron.left").font(.title3).opacity(0).padding(8)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 32) {
                        
                        // 1. Avatar Picker
                        VStack(spacing: 12) {
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: [accent, RainbowColors.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 120, height: 120)
                                        .shadow(color: accent.opacity(0.5), radius: 20, x: 0, y: 10)
                                    
                                    if let data = selectedImageData, let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 112, height: 112)
                                            .clipShape(Circle())
                                    } else {
                                        Text(name.prefix(1).uppercased())
                                            .font(.system(size: 40, weight: .black))
                                            .foregroundColor(.white)
                                    }
                                    
                                    // Edit Overlay
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Image(systemName: "camera.fill")
                                                .font(.caption).fontWeight(.bold)
                                                .foregroundColor(.black)
                                                .padding(8)
                                                .background(Color.white)
                                                .clipShape(Circle())
                                                .shadow(radius: 4)
                                        }
                                    }
                                    .frame(width: 120, height: 120)
                                }
                            }
                            
                            Text("TAP TO CHANGE")
                                .font(.caption).fontWeight(.black)
                                .foregroundColor(accent)
                                .tracking(1)
                        }
                        
                        // 2. Form Fields
                        VStack(spacing: 20) {
                            RainbowTextField(icon: "person.fill", title: "Full Name", text: $name, color: RainbowColors.blue)
                            RainbowTextField(icon: "envelope.fill", title: "Email", text: $email, color: RainbowColors.purple)
                            RainbowTextField(icon: "building.columns.fill", title: "University", text: $university, color: RainbowColors.orange)
                            RainbowTextField(icon: "book.fill", title: "Major / Faculty", text: $major, color: RainbowColors.green)
                            RainbowTextField(icon: "graduationcap.fill", title: "Academic Year", text: $academicYear, color: accent)
                        }
                        .padding()
                        
                        Spacer()
                        
                        // 3. Save Button
                        Button(action: saveChanges) {
                            Text("SAVE CHANGES")
                                .font(.headline).fontWeight(.black)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(colors: [accent, RainbowColors.purple], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(20)
                                .shadow(color: accent.opacity(0.5), radius: 10, y: 5)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { loadData() }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    await MainActor.run { selectedImageData = data }
                }
            }
        }
    }
    
    private func loadData() {
        if let profile = currentProfile {
            self.name = profile.name
            self.email = profile.email
            self.university = profile.university
            self.major = profile.major
            self.academicYear = profile.academicYear
            self.selectedImageData = profile.profileImageData
        } else {
            ensureProfileExists()
        }
    }
    
    private func ensureProfileExists() {
        if let session = authManager.userSession {
            let existingAppUser = appUsers.first { $0.id == session.uid }
            let newProfile = StudentProfile(
                id: session.uid,
                name: session.fullName ?? "Student",
                email: session.email ?? "",
                university: existingAppUser?.universityName ?? "",
                major: existingAppUser?.facultyName ?? "",
                gradeLevel: existingAppUser?.yearOfStudy ?? "",
                academicYear: existingAppUser?.academicYear ?? ""
            )
            modelContext.insert(newProfile)
            try? modelContext.save()
            self.name = newProfile.name
            self.email = newProfile.email
            self.university = newProfile.university
            self.major = newProfile.major
            self.academicYear = newProfile.academicYear
        }
    }
    
    private func saveChanges() {
        if currentProfile == nil { ensureProfileExists() }
        if let profile = currentProfile {
            profile.name = name
            profile.email = email
            profile.university = university
            profile.major = major
            profile.academicYear = academicYear
            profile.profileImageData = selectedImageData
            try? modelContext.save()
            if let appUser = appUsers.first(where: { $0.id == profile.id }) {
                appUser.fullName = name
                appUser.email = email
                appUser.universityName = university
                appUser.facultyName = major
            }
            dismiss()
        }
    }
}

// MARK: - 👔 STANDARD PROFILE
struct StandardProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthenticationManager.self) private var authManager
    @EnvironmentObject var themeManager: AppTheme
    
    @Query private var profiles: [StudentProfile]
    @Query private var appUsers: [AppUser]
    
    @State private var name: String = ""
    @State private var university: String = ""
    @State private var major: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    var currentProfile: StudentProfile? {
        guard let uid = authManager.userSession?.uid else { return profiles.first }
        return profiles.first(where: { $0.id == uid }) ?? profiles.first
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            if let data = selectedImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(themeManager.selectedTheme.primaryColor, lineWidth: 2))
                            } else {
                                ZStack {
                                    Circle().fill(themeManager.selectedTheme.primaryColor.opacity(0.1))
                                        .frame(width: 100, height: 100)
                                    Image(systemName: "camera.fill")
                                        .font(.title)
                                        .foregroundColor(themeManager.selectedTheme.primaryColor)
                                }
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                Section {
                    TextField("Name", text: $name)
                    TextField("University", text: $university)
                    TextField("Major / Faculty", text: $major)
                } header: {
                    Text("PERSONAL INFO")
                        .font(.caption).fontWeight(.black) // Bolder Header
                        .foregroundColor(themeManager.selectedTheme.primaryColor)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { saveChanges() }
                        .fontWeight(.bold)
                }
            }
        }
        .onAppear { loadData() }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    await MainActor.run { selectedImageData = data }
                }
            }
        }
    }
    
    private func loadData() {
        if let p = currentProfile {
            name = p.name
            university = p.university
            major = p.major
            selectedImageData = p.profileImageData
        } else {
            ensureProfileExists()
        }
    }
    
    private func ensureProfileExists() {
        if let session = authManager.userSession {
            let existingAppUser = appUsers.first { $0.id == session.uid }
            let newProfile = StudentProfile(
                id: session.uid,
                name: session.fullName ?? "Student",
                email: session.email ?? "",
                university: existingAppUser?.universityName ?? "",
                major: existingAppUser?.facultyName ?? ""
            )
            modelContext.insert(newProfile)
            try? modelContext.save()
            self.name = newProfile.name
            self.university = newProfile.university
            self.major = newProfile.major
        }
    }
    
    func saveChanges() {
        if currentProfile == nil { ensureProfileExists() }
        if let p = currentProfile {
            p.name = name
            p.university = university
            p.major = major
            p.profileImageData = selectedImageData
            try? modelContext.save()
            dismiss()
        }
    }
}

// MARK: - Helper Components

struct RainbowTextField: View {
    let icon: String
    let title: String
    @Binding var text: String
    var color: Color = .white // Added color param
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color.opacity(0.8)) // Tinted Label
                .padding(.leading, 4)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color) // Tinted Icon
                    .frame(width: 20)
                
                TextField("", text: $text)
                    .foregroundColor(.white)
                    .tint(color)
            }
            .padding()
            .background(Color(white: 0.12)) // Slightly lighter bg
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1) // Tinted Border
            )
        }
    }
}
