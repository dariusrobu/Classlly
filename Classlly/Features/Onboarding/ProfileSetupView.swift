import SwiftUI
import SwiftData

@MainActor
struct ProfileSetupView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.modelContext) private var modelContext
    
    // The user object we are editing
    let user: StudentProfile
    
    // Local State for Form Fields
    @State private var name: String
    @State private var university: String = ""
    @State private var gradeLevel: String = ""
    @State private var major: String = ""
    @State private var academicYear: String = ""
    
    // Image Handling
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    
    private let educationLevels = ["High School", "Bachelor's Degree", "Master's Degree", "PhD", "Other"]
    
    // ✅ FIX: changed from calendar years to "Year 1" - "Year 7"
    private let academicYears = (1...7).map { "Year \($0)" }
    
    private let popularMajors = [
        "Computer Science", "Engineering", "Business", "Medicine", "Law",
        "Psychology", "Biology", "Chemistry", "Physics", "Mathematics",
        "Economics", "Political Science", "History", "English", "Art",
        "Music", "Architecture", "Education", "Nursing", "Other"
    ]
    
    init(user: StudentProfile) {
        self.user = user
        _name = State(initialValue: user.name)
        _university = State(initialValue: user.university)
        _gradeLevel = State(initialValue: user.gradeLevel)
        _major = State(initialValue: user.major)
        _academicYear = State(initialValue: user.academicYear)
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
                                    Image(uiImage: inputImage).resizable().scaledToFill().frame(width: 100, height: 100).clipShape(Circle())
                                } else if let data = user.profileImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 100, height: 100).clipShape(Circle())
                                } else {
                                    Circle().fill(Color.gray.opacity(0.2)).frame(width: 100, height: 100)
                                    Image(systemName: "camera.fill").font(.title).foregroundColor(.gray)
                                }
                                VStack { Spacer(); HStack { Spacer(); Image(systemName: "pencil.circle.fill").font(.title2).foregroundColor(.blue).background(Circle().fill(Color.white)) } }.frame(width: 100, height: 100)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)
                
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $name).textContentType(.name)
                }
                
                Section(header: Text("Academic Information")) {
                    TextField("School/University Name", text: $university).textInputAutocapitalization(.words)
                    
                    Picker("Education Level", selection: $gradeLevel) {
                        Text("Select Education Level").tag("")
                        ForEach(educationLevels, id: \.self) { Text($0).tag($0) }
                    }
                    
                    Picker("Major/Field of Study", selection: $major) {
                        Text("Select Major").tag("")
                        ForEach(popularMajors, id: \.self) { Text($0).tag($0) }
                    }
                    
                    Picker("Academic Year", selection: $academicYear) {
                        Text("Select Year").tag("")
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
                    Button("Sign Out") { authManager.signOut() }.foregroundColor(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Continue") { completeProfile() }.disabled(!isFormValid).fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker { image in self.inputImage = image }
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !university.isEmpty && !gradeLevel.isEmpty
    }
    
    private func completeProfile() {
        // 1. Update the User Model
        user.name = name
        user.university = university
        user.gradeLevel = gradeLevel
        user.major = major
        user.academicYear = academicYear
        if let img = inputImage {
            user.profileImageData = img.jpegData(compressionQuality: 0.8)
        }
        
        // 2. Finalize via AuthenticationManager (which will save the context)
        authManager.completeProfileSetup(modelContext: modelContext)
        dismiss()
    }
}
