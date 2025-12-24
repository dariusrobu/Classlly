import SwiftUI
import SwiftData

struct ProfileSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthenticationManager.self) private var authManager
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme
    
    // MARK: - State
    @State private var fullName: String = ""
    @State private var selectedUniversity: String = ""
    @State private var customUniversity: String = ""
    @State private var faculty: String = ""
    @State private var yearOfStudy: String = ""
    @State private var group: String = ""
    @State private var isSettingUp = false
    
    // Hardcoded popular options as requested
    private let universityOptions = ["UBB", "UTCN", "UMF", "Other"]
    
    var body: some View {
        ZStack {
            // 1. Background Gradient (Matches SignIn/Rainbow Theme)
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.4, blue: 0.6), // Pinkish
                    Color(red: 0.6, green: 0.2, blue: 0.8), // Purple
                    Color(red: 1.0, green: 0.6, blue: 0.2)  // Orange accent
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(0.9)
            
            // 2. Content ScrollView
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 80))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                            .padding(.top, 40)
                        
                        Text("Welcome, Student!")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("Let's set up your profile to personalize your experience.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 40)
                    }
                    
                    // Form Card
                    VStack(spacing: 24) {
                        
                        // Full Name
                        SetupTextField(icon: "person.fill", placeholder: "Full Name", text: $fullName)
                        
                        // University Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("UNIVERSITY")
                                .font(.caption).fontWeight(.bold).foregroundStyle(.white.opacity(0.7))
                                .padding(.leading, 4)
                            
                            // Chips
                            HStack(spacing: 10) {
                                ForEach(universityOptions, id: \.self) { option in
                                    Button(action: {
                                        withAnimation(.spring()) {
                                            selectedUniversity = option
                                            // Reset custom if switching away from Other
                                            if option != "Other" { customUniversity = "" }
                                        }
                                    }) {
                                        Text(option)
                                            .font(.system(size: 14, weight: .bold))
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 16)
                                            .background(selectedUniversity == option ? Color.white : Color.white.opacity(0.15))
                                            .foregroundColor(selectedUniversity == option ? .purple : .white)
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            
                            // Custom Input if "Other"
                            if selectedUniversity == "Other" {
                                SetupTextField(icon: "building.columns.fill", placeholder: "Type your University name", text: $customUniversity)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        
                        // Faculty & Year
                        SetupTextField(icon: "book.fill", placeholder: "Faculty", text: $faculty)
                        
                        HStack(spacing: 16) {
                            SetupTextField(icon: "graduationcap.fill", placeholder: "Year", text: $yearOfStudy)
                            SetupTextField(icon: "person.3.fill", placeholder: "Group", text: $group)
                        }
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .cornerRadius(30)
                    .padding(.horizontal, 20)
                    .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 5)
                    
                    Spacer(minLength: 20)
                    
                    // Action Button
                    Button(action: saveProfile) {
                        HStack {
                            if isSettingUp {
                                ProgressView().tint(.purple)
                            } else {
                                Text("Get Started")
                                    .fontWeight(.bold)
                                Image(systemName: "arrow.right")
                            }
                        }
                        .foregroundStyle(isValid ? .purple : .gray)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    }
                    .disabled(!isValid || isSettingUp)
                    .opacity(isValid ? 1.0 : 0.6)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            // Pre-fill email or name if available from Auth
            if let user = authManager.userSession {
                if fullName.isEmpty { fullName = user.fullName ?? "" }
            }
        }
    }
    
    // MARK: - Validation
    var isValid: Bool {
        let uniValid = selectedUniversity == "Other" ? !customUniversity.isEmpty : !selectedUniversity.isEmpty
        return !fullName.isEmpty && uniValid
    }
    
    // MARK: - Logic
    
    private func saveProfile() {
        guard let uid = authManager.userSession?.uid else { return }
        isSettingUp = true
        
        // 1. Determine final University Name
        let finalUniName = selectedUniversity == "Other" ? customUniversity : selectedUniversity
        
        // 2. Create/Update Student Profile (Source of Truth for Dashboard)
        let newProfile = StudentProfile(
            id: uid,
            name: fullName,
            email: authManager.userSession?.email ?? "",
            university: finalUniName,
            major: faculty,
            gradeLevel: yearOfStudy,
            academicYear: "2023-2024" // Default, can be updated later
        )
        // Also store group info if added to model later, for now we map it to 'academicYear' or similar if needed,
        // or just keep it in AppUser. Let's put it in `gradeLevel` combined or just AppUser.
        // The prompt asked for Group field, effectively used for display.
        
        modelContext.insert(newProfile)
        
        // 3. Update AppUser (For Auth/Sync consistency)
        let appUser = AppUser(id: uid, email: authManager.userSession?.email, fullName: fullName)
        appUser.universityName = finalUniName
        appUser.facultyName = faculty
        appUser.yearOfStudy = yearOfStudy
        appUser.group = group
        modelContext.insert(appUser)
        
        // 4. Auto-Select Calendar Logic
        if ["UBB", "UTCN", "UMF"].contains(selectedUniversity) {
            applyAutoCalendar(for: selectedUniversity)
        }
        
        // 5. Save & Finish
        try? modelContext.save()
        
        // Delay slightly for UX effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            authManager.completeOnboarding()
            isSettingUp = false
        }
    }
    
    private func applyAutoCalendar(for university: String) {
        // Find a template that vaguely matches the University name
        // This relies on the fetched templates in AcademicCalendarManager
        
        // Common mappings
        let searchTerms: [String] = {
            switch university {
            case "UBB": return ["UBB", "Babes", "Bolyai"]
            case "UTCN": return ["UTCN", "Technical"]
            case "UMF": return ["UMF", "Medicine", "Iuliu Hatieganu"]
            default: return [university]
            }
        }()
        
        if let match = calendarManager.availableTemplates.first(where: { template in
            searchTerms.contains { term in
                template.universityName.localizedCaseInsensitiveContains(term)
            }
        }) {
            print("✅ Auto-selected calendar: \(match.universityName)")
            calendarManager.generateAndSaveCalendar(from: match)
        } else {
            print("⚠️ No matching calendar template found for \(university). Using default.")
        }
    }
}

// MARK: - Components

struct SetupTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 20)
            
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.5)))
                .foregroundColor(.white)
                .tint(.white)
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    ProfileSetupView()
        .environment(AuthenticationManager())
        .environmentObject(AcademicCalendarManager.shared)
}
