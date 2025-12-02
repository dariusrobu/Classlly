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
    @Published var requiresOnboarding: Bool = false
    @Published var universityNameForOnboarding: String = ""

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    // --- NEW: Track if we are in Demo Mode ---
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
    
    @MainActor
    func checkAuthentication(modelContext: ModelContext) {
        if isAuthenticated { return }
        
        // Safety: If we think we are in demo mode but relaunching,
        // we might want to stay logged in or reset.
        // For now, standard logic: check for profile.
        
        let descriptor = FetchDescriptor<StudentProfile>()
        
        do {
            let profiles = try modelContext.fetch(descriptor)
            if let profile = profiles.first {
                print("Found existing profile: \(profile.firstName)")
                self.currentUser = profile.toUserProfile()
                self.isAuthenticated = true
                self.universityNameForOnboarding = profile.schoolName
                
                if !hasCompletedOnboarding && !profile.schoolName.isEmpty {
                    self.requiresOnboarding = true
                }
                // If we found a real profile, ensure demo mode is OFF
                self.isDemoUser = false
            } else {
                // No profile found.
                // Ensure we aren't stuck in a weird demo state
                self.isDemoUser = false
            }
        } catch {
            print("Failed to fetch profiles: \(error)")
        }
    }
    
    func handleSignInWithApple(result: Result<ASAuthorization, Error>, modelContext: ModelContext) {
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userIdentifier = appleIDCredential.user
                
                // Ensure Demo Mode is OFF for Apple Sign In
                self.isDemoUser = false
                
                let descriptor = FetchDescriptor<StudentProfile>(predicate: #Predicate<StudentProfile> { profile in
                    profile.id == userIdentifier
                })
                
                do {
                    let existingProfiles = try modelContext.fetch(descriptor)
                    
                    if let existingProfile = existingProfiles.first {
                        self.currentUser = existingProfile.toUserProfile()
                        self.isAuthenticated = true
                        self.universityNameForOnboarding = existingProfile.schoolName
                        self.isLoading = false
                    } else {
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
        self.isLoading = false
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
        
        let descriptor = FetchDescriptor<StudentProfile>(predicate: #Predicate<StudentProfile> { p in
            p.id == profile.id
        })
        
        do {
            let results = try modelContext.fetch(descriptor)
            if let existing = results.first {
                existing.firstName = profile.firstName
                existing.lastName = profile.lastName
                existing.schoolName = profile.schoolName
                existing.gradeLevel = profile.gradeLevel
                existing.major = profile.major
                existing.academicYear = profile.academicYear
            } else {
                modelContext.insert(studentProfile)
            }
            try? modelContext.save() // Explicit save
            
            self.currentUser = profile
            self.isAuthenticated = true
            self.universityNameForOnboarding = profile.schoolName
            self.isDemoUser = false // Ensure false
            
            if !self.hasCompletedOnboarding {
                self.requiresOnboarding = true
            }
            
        } catch {
            print("Failed to save profile: \(error)")
            errorMessage = "Failed to save profile."
        }
    }
    
    func signInAsDemoUser() {
        self.currentUser = AuthenticationManager.demoUser
        self.isAuthenticated = true
        self.hasCompletedOnboarding = true
        self.requiresOnboarding = false
        // --- TURN ON DEMO MODE ---
        self.isDemoUser = true
    }
    
    // --- UPDATED: Sign Out with Cleanup ---
    @MainActor
    func signOut(modelContext: ModelContext) {
        // If we were in demo mode, WIPE EVERYTHING
        if isDemoUser {
            print("Signing out Demo User. Wiping data...")
            DemoDataManager.shared.deleteAllData(modelContext: modelContext)
            isDemoUser = false
        }
        
        isAuthenticated = false
        currentUser = nil
        hasCompletedOnboarding = false
        universityNameForOnboarding = ""
    }
    
    // ... (Helpers randomNonceString, sha256 unchanged) ...
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// (UserProfile struct unchanged)
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
