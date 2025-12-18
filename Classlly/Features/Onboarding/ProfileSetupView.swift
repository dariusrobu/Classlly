import SwiftUI
import SwiftData

struct ProfileSetupView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.modelContext) private var modelContext
    
    // Changed from UserProfile to StudentProfile
    let user: StudentProfile
    
    // ✅ Updated to match StudentProfile (single name field)
    @State private var name: String
    @State private var university: String = ""
    @State private var gradeLevel: String = "" // Was educationLevel
    @State private var major: String = ""
    @State private var academicYear: String = ""
    
    // Image Handling
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    
    private let educationLevels = ["High School", "Bachelor's Degree", "Master's Degree", "PhD", "Other"]
    private let academicYears = ["2023-2024", "2024-2025", "2025-2026", "2026-2027", "2027-2028"]
    private let popularMajors = [
        "Computer Science", "Engineering", "Business", "Medicine", "Law",
        "Psychology", "Biology", "Chemistry", "Physics", "Mathematics",
        "Economics", "Political Science", "History", "English", "Art",
        "Music", "Architecture", "Education", "Nursing", "Other"
    ]
    
    init(user: StudentProfile) {
        self.user = user
        // ✅ Initialize with single name
        _name = State(initialValue: user.name)
        _university = State(initialValue: user.university)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Profile Picture Section
                Section {
                    HStack {
                        Spacer()
                        Button(action: { showingImagePicker = true }) {
                            ZStack {
                                if let inputImage = inputImage {
                                    Image(uiImage: inputImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 100, height: 100)
                                    
                                    Image(systemName: "camera.fill")
                                        .font(.title)
                                        .foregroundColor(.gray)
                                }
                                
                                // Edit badge
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.blue)
                                            .background(Circle().fill(Color.white))
                                    }
                                }
                                .frame(width: 100, height: 100)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)
                
                Section(header: Text("Personal Information")) {
                    // ✅ Single Full Name Field
                    TextField("Full Name", text: $name)
                        .textContentType(.name)
                }
                
                Section(header: Text("Academic Information")) {
                    // ✅ Mapped to university
                    TextField("School/University Name", text: $university)
                        .textInputAutocapitalization(.words)
                    
                    // ✅ Mapped to gradeLevel
                    Picker("Education Level", selection: $gradeLevel) {
                        Text("Select Education Level").tag("")
                        ForEach(educationLevels, id: \.self) { Text($0).tag($0) }
                    }
                    
                    Picker("Major/Field of Study", selection: $major) {
                        Text("Select Major").tag("")
                        ForEach(popularMajors, id: \.self) { Text($0).tag($0) }
                    }
                    
                    Picker("Academic Year", selection: $academicYear) {
                        Text("Select Academic Year").tag("")
                        ForEach(academicYears, id: \.self) { Text($0).tag($0) }
                    }
                }
                
                Section(footer: Text("By completing your profile, you agree to our Terms of Service and Privacy Policy")) {
                    EmptyView()
                }
            }
            .navigationTitle("Complete Your Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // ✅ FIX: signOut takes no arguments now
                        authManager.signOut()
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Continue") {
                        completeProfile()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker { image in
                    self.inputImage = image
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !university.isEmpty && !gradeLevel.isEmpty && !academicYear.isEmpty
    }
    
    private func completeProfile() {
        // ✅ Update properties to match new StudentProfile model
        user.name = name
        user.university = university
        user.gradeLevel = gradeLevel
        // major is now a String, so we just assign it directly (no need for nil check if it defaults to empty string)
        user.major = major
        user.academicYear = academicYear
        user.profileImageData = inputImage?.jpegData(compressionQuality: 0.8)
        
        // Pass the updated StudentProfile object
        authManager.completeProfileSetup(profile: user, modelContext: modelContext)
        dismiss()
    }
}
