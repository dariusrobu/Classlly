import SwiftUI
import AuthenticationServices
import CryptoKit
import Combine
import SwiftData

class AuthenticationManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Sticky Onboarding Flags
    @AppStorage("hasCompletedStickyOnboarding") var hasCompletedStickyOnboarding: Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedLegacyOnboarding: Bool = false
    @Published var requiresOnboarding: Bool = false
    @Published var universityNameForOnboarding: String = ""

    @AppStorage("isDemoUser") var isDemoUser: Bool = false
    
    var currentNonce: String?
    
    static let demoUser = UserProfile(
        id: "demo-user-001",
        firstName: "Demo",
        lastName: "Student",
        email: "demo@classlly.app",
        schoolName: "University of Example",
        gradeLevel: "Bachelor's Degree",
        major: "Computer Science",
        academicYear: "2024-2025",
        profileImageData: nil
    )
    
    override init() {
        super.init()
    }
    
    // MARK: - Authentication Logic
    
    @MainActor
    func checkAuthentication(modelContext: ModelContext) {
        if isAuthenticated { return }
        
        if isDemoUser {
            signInAsDemoUser()
            return
        }
        
        let descriptor = FetchDescriptor<StudentProfile>()
        
        do {
            let profiles = try modelContext.fetch(descriptor)
            if let profile = profiles.first {
                print("Found existing profile: \(profile.firstName)")
                self.currentUser = profile.toUserProfile()
                self.isAuthenticated = true
                self.universityNameForOnboarding = profile.schoolName
                self.isDemoUser = false
                
                if hasCompletedLegacyOnboarding {
                    hasCompletedStickyOnboarding = true
                }
            }
        } catch {
            print("Failed to fetch profiles: \(error)")
        }
    }
    
    func completeStickyOnboarding() {
        self.hasCompletedStickyOnboarding = true
        self.hasCompletedLegacyOnboarding = true
        self.requiresOnboarding = false
    }
    
    // MARK: - Testing / Reset Logic
    
    /// Nukes all data to simulate a fresh install
    @MainActor
    func resetAppForTesting(modelContext: ModelContext) {
        // 1. Reset Flags
        hasCompletedStickyOnboarding = false
        hasCompletedLegacyOnboarding = false
        isDemoUser = false
        requiresOnboarding = false
        
        // 2. Delete Student Profile (This makes you a "New User" next time)
        try? modelContext.delete(model: StudentProfile.self)
        
        // 3. Delete All Data
        DemoDataManager.shared.deleteAllData(modelContext: modelContext)
        
        // 4. Sign Out
        isAuthenticated = false
        currentUser = nil
        
        // 5. Force Save
        try? modelContext.save()
        print("🚨 App Reset Complete: User is now 'New'")
    }
    
    func handleSignInWithApple(result: Result<ASAuthorization, Error>, modelContext: ModelContext) {
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userIdentifier = appleIDCredential.user
                self.isDemoUser = false
                
                let descriptor = FetchDescriptor<StudentProfile>(predicate: #Predicate<StudentProfile> { profile in
                    profile.id == userIdentifier
                })
                
                do {
                    let existingProfiles = try modelContext.fetch(descriptor)
                    
                    if let existingProfile = existingProfiles.first {
                        // Returning User -> Skip Flow
                        self.currentUser = existingProfile.toUserProfile()
                        self.isAuthenticated = true
                        self.universityNameForOnboarding = existingProfile.schoolName
                        self.isLoading = false
                        self.hasCompletedStickyOnboarding = true
                    } else {
                        // New User -> Show Flow
                        processAppleIDCredential(appleIDCredential)
                    }
                } catch {
                    print("Error fetching user: \(error)")
                    processAppleIDCredential(appleIDCredential)
                }
            }
        case .failure(let error):
            isLoading = false
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
    }
    
    private func processAppleIDCredential(_ credential: ASAuthorizationAppleIDCredential) {
        let userIdentifier = credential.user
        let firstName = credential.fullName?.givenName ?? ""
        let lastName = credential.fullName?.familyName ?? ""
        let email = credential.email ?? ""
        
        let tempUser = UserProfile(
            id: userIdentifier,
            firstName: firstName.isEmpty ? "Student" : firstName,
            lastName: lastName.isEmpty ? "Name" : lastName,
            email: email.isEmpty ? nil : email,
            schoolName: "",
            gradeLevel: "",
            major: nil,
            academicYear: ""
        )
        
        self.currentUser = tempUser
        self.isAuthenticated = true
        self.isLoading = false
        // hasCompletedStickyOnboarding remains FALSE, triggering flow
    }
    
    @MainActor
    func completeProfileSetup(profile: UserProfile, modelContext: ModelContext) {
        let studentProfile = StudentProfile(
            id: profile.id,
            firstName: profile.firstName,
            lastName: profile.lastName,
            email: profile.email,
            schoolName: profile.schoolName,
            gradeLevel: profile.gradeLevel,
            major: profile.major,
            academicYear: profile.academicYear
        )
        
        modelContext.insert(studentProfile)
        
        self.currentUser = profile
        self.isAuthenticated = true
        self.universityNameForOnboarding = profile.schoolName
        self.hasCompletedLegacyOnboarding = true
        self.hasCompletedStickyOnboarding = true
        self.requiresOnboarding = false
    }
    
    func signInAsDemoUser() {
        self.currentUser = AuthenticationManager.demoUser
        self.isAuthenticated = true
        self.hasCompletedStickyOnboarding = true
        self.hasCompletedLegacyOnboarding = true
        self.requiresOnboarding = false
        self.isDemoUser = true
    }
    
    @MainActor
    func signOut(modelContext: ModelContext) {
        if isDemoUser {
            DemoDataManager.shared.deleteAllData(modelContext: modelContext)
            isDemoUser = false
        }
        isAuthenticated = false
        currentUser = nil
    }
    
    // MARK: - Crypto Helpers
    
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""; var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess { fatalError("Unable to generate nonce") }
                return random
            }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count { result.append(charset[Int(random)]); remainingLength -= 1 }
            }
        }
        return result
    }
    
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - UserProfile Model
struct UserProfile: Codable, Equatable {
    let id: String
    var firstName: String
    var lastName: String
    var email: String?
    var schoolName: String
    var gradeLevel: String
    var major: String?
    var academicYear: String
    var profileImageData: Data?
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        return lhs.id == rhs.id
    }
}
