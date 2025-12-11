import SwiftUI
import SwiftData

// MARK: - MAIN SWITCHER
struct ProfileView: View {
    @EnvironmentObject var themeManager: AppTheme
    @EnvironmentObject var authManager: AuthenticationManager
    @Query var subjects: [Subject]
    @Query var tasks: [StudyTask]
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                RainbowProfileView(user: authManager.currentUser, subjects: subjects, tasks: tasks)
            case .arcade:
                ArcadeProfileView(user: authManager.currentUser, subjects: subjects, tasks: tasks)
            case .none:
                StandardProfileView(user: authManager.currentUser, subjects: subjects, tasks: tasks)
            }
        }
    }
}

// MARK: - 🌈 RAINBOW PROFILE VIEW (Dynamic Color)
struct RainbowProfileView: View {
    let user: UserProfile?
    let subjects: [Subject]
    let tasks: [StudyTask]
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: AppTheme
    @Environment(\.modelContext) var modelContext
    @State private var showingEditProfile = false
    
    var body: some View {
        let accentColor = themeManager.selectedTheme.primaryColor
        
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if let user = user {
                            // 1. Profile Header Card
                            VStack(spacing: 16) {
                                ZStack {
                                    if let data = user.profileImageData, let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                    } else {
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .frame(width: 100, height: 100)
                                        
                                        Text(String(user.firstName.prefix(1)))
                                            .font(.system(size: 40, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                                
                                VStack(spacing: 4) {
                                    Text(user.fullName)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text(user.schoolName)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text(user.gradeLevel)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(8)
                                        .foregroundColor(.white)
                                        .padding(.top, 4)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(24)
                            .background(accentColor)
                            .cornerRadius(24)
                            .padding(.horizontal)
                            .shadow(color: accentColor.opacity(0.4), radius: 15, x: 0, y: 5)
                            
                            // 2. Stats Grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                RainbowStatBox(
                                    title: "Subjects",
                                    value: "\(subjects.count)",
                                    icon: "book.fill",
                                    color: RainbowColors.purple
                                )
                                
                                RainbowStatBox(
                                    title: "Active Tasks",
                                    value: "\(tasks.filter { !$0.isCompleted }.count)",
                                    icon: "checklist",
                                    color: RainbowColors.orange
                                )
                            }
                            .padding(.horizontal)
                            
                            // 3. Academic Info
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Academic Details").font(.headline).foregroundColor(.white).padding(.horizontal)
                                
                                RainbowContainer {
                                    VStack(spacing: 16) {
                                        ProfileInfoRow(icon: "graduationcap.fill", label: "Major", value: user.major ?? "Undeclared", color: RainbowColors.green)
                                        Divider().background(Color.gray.opacity(0.3))
                                        ProfileInfoRow(icon: "calendar", label: "Year", value: user.academicYear, color: accentColor)
                                        Divider().background(Color.gray.opacity(0.3))
                                        ProfileInfoRow(icon: "envelope.fill", label: "Email", value: user.email ?? "No Email", color: RainbowColors.orange)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // 4. Sign Out
                            Button(action: {
                                authManager.signOut(modelContext: modelContext)
                            }) {
                                Text("Sign Out")
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(RainbowColors.darkCard)
                                    .cornerRadius(16)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingEditProfile = true }) {
                        Text("Edit")
                            .fontWeight(.bold)
                            .foregroundColor(accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                if let user = authManager.currentUser {
                    EditProfileView(user: user)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// Helper Row for Profile
struct ProfileInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .foregroundColor(.gray)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
}

// MARK: - EDIT PROFILE VIEW
struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: AppTheme
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var schoolName: String
    @State private var major: String
    @State private var academicYear: String
    
    // Image Handling
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    
    let user: UserProfile
    
    init(user: UserProfile) {
        self.user = user
        _firstName = State(initialValue: user.firstName)
        _lastName = State(initialValue: user.lastName)
        _schoolName = State(initialValue: user.schoolName)
        _major = State(initialValue: user.major ?? "")
        _academicYear = State(initialValue: user.academicYear)
        
        if let data = user.profileImageData, let image = UIImage(data: data) {
            _inputImage = State(initialValue: image)
        }
    }
    
    var body: some View {
        let accentColor = themeManager.selectedTheme.primaryColor
        
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Image Picker
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
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 100, height: 100)
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.white)
                                }
                                // Edit Overlay
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Image(systemName: "pencil.circle.fill")
                                            .foregroundColor(accentColor)
                                            .background(Circle().fill(Color.white))
                                    }
                                }
                                .frame(width: 100, height: 100)
                            }
                        }
                        
                        RainbowContainer {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Personal Info").font(.headline).foregroundColor(.gray)
                                
                                CustomTextField(placeholder: "First Name", text: $firstName, color: accentColor)
                                CustomTextField(placeholder: "Last Name", text: $lastName, color: accentColor)
                            }
                        }
                        
                        RainbowContainer {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Academic Info").font(.headline).foregroundColor(.gray)
                                
                                CustomTextField(placeholder: "University/School", text: $schoolName, color: accentColor)
                                CustomTextField(placeholder: "Major", text: $major, color: accentColor)
                                CustomTextField(placeholder: "Academic Year", text: $academicYear, color: accentColor)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(accentColor)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker { image in
                    self.inputImage = image
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func saveProfile() {
        let imageData = inputImage?.jpegData(compressionQuality: 0.8)
        
        // 1. Create the updated struct
        let updatedProfile = UserProfile(
            id: user.id,
            firstName: firstName,
            lastName: lastName,
            email: user.email,
            schoolName: schoolName,
            gradeLevel: user.gradeLevel,
            major: major,
            academicYear: academicYear,
            profileImageData: imageData
        )
        
        // 2. Update Global State IMMEDIATELY (Fixes "Nothing Happens" bug)
        authManager.currentUser = updatedProfile
        
        // 3. Try to persist to Database
        let id = user.id
        let descriptor = FetchDescriptor<StudentProfile>(predicate: #Predicate<StudentProfile> { p in
            p.id == id
        })
        
        do {
            if let profile = try modelContext.fetch(descriptor).first {
                profile.firstName = firstName
                profile.lastName = lastName
                profile.schoolName = schoolName
                profile.major = major
                profile.academicYear = academicYear
                profile.profileImageData = imageData
                
                try modelContext.save()
                print("✅ Profile saved to database")
            } else {
                print("⚠️ Profile not found in database (Demo User?), updated in-memory only.")
            }
        } catch {
            print("❌ Failed to save profile to DB: \(error)")
        }
        
        dismiss()
    }
}

// Helper TextField for Rainbow Forms
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    var color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(placeholder)
                .font(.caption)
                .foregroundColor(color)
                .fontWeight(.bold)
            
            TextField("", text: $text)
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(10)
                .foregroundColor(.white)
        }
    }
}

// MARK: - 👔 STANDARD VIEW
struct StandardProfileView: View {
    let user: UserProfile?
    let subjects: [Subject]
    let tasks: [StudyTask]
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.modelContext) var modelContext
    @State private var showingEditProfile = false
    
    var body: some View {
        ScrollView {
            if let user = user {
                VStack(spacing: 24) {
                    // Avatar & Name
                    VStack(spacing: 16) {
                        ZStack {
                            if let data = user.profileImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [.themePrimary, .themeSecondary]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 100, height: 100)
                                
                                Text(String(user.firstName.prefix(1)))
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        VStack(spacing: 4) {
                            Text(user.fullName)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(user.schoolName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(user.gradeLevel)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.themeSurface)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Stats")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            StatBox(title: "Subjects", value: "\(subjects.count)")
                            StatBox(title: "Tasks", value: "\(tasks.count)")
                        }
                        .padding(.horizontal)
                    }
                    
                    // Account Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Account")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            Button(action: {
                                authManager.signOut(modelContext: modelContext)
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .foregroundColor(.red)
                                    Text("Sign Out")
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.themeSurface)
                            }
                        }
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .background(Color.themeBackground)
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditProfile = true
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            if let user = authManager.currentUser {
                EditProfileView(user: user)
            }
        }
    }
}

// MARK: - 🕹️ ARCADE VIEW
struct ArcadeProfileView: View {
    let user: UserProfile?
    let subjects: [Subject]
    let tasks: [StudyTask]
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.modelContext) var modelContext
    @State private var showingEditProfile = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    if let user = user {
                        // Avatar
                        ZStack {
                            Circle()
                                .stroke(Color.cyan, lineWidth: 3)
                                .frame(width: 110, height: 110)
                            
                            if let data = user.profileImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.purple.opacity(0.5))
                                    .frame(width: 100, height: 100)
                                
                                Text(String(user.firstName.prefix(1)))
                                    .font(.system(size: 40, weight: .black))
                                    .foregroundColor(.white)
                            }
                        }
                        .shadow(color: .cyan, radius: 10)
                        
                        // Info
                        VStack(spacing: 8) {
                            Text(user.fullName.uppercased())
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.black)
                                .foregroundColor(.white)
                            
                            Text("CLASS: \(user.gradeLevel.uppercased())")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            
                            Text("GUILD: \(user.schoolName.uppercased())")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                        }
                        
                        // Stats
                        HStack(spacing: 16) {
                            ArcadeStatPill(icon: "bolt.fill", value: "\(subjects.count)", label: "Skills", gradient: Gradient(colors: [.blue, .purple]))
                            ArcadeStatPill(icon: "flame.fill", value: "\(tasks.count)", label: "Quests", gradient: Gradient(colors: [.orange, .red]))
                        }
                        .padding()
                        
                        // Logout
                        Button(action: {
                            authManager.signOut(modelContext: modelContext)
                        }) {
                            Text("LOGOUT")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.black)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.2))
                                .foregroundColor(.red)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
        }
        .navigationTitle("Player Stats")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingEditProfile = true }) {
                    Text("EDIT PLAYER")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.black)
                        .foregroundColor(.cyan)
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            if let user = authManager.currentUser {
                EditProfileView(user: user)
            }
        }
    }
}
