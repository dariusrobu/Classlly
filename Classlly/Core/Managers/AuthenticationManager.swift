import SwiftUI
import AuthenticationServices
import CryptoKit
import Combine
import SwiftData

@MainActor
class AuthenticationManager: ObservableObject {
    // Persist the User ID even if app is killed
    @AppStorage("storedUserId") var storedUserId: String = ""
    
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var requiresOnboarding: Bool = false
    @Published var universityNameForOnboarding: String = ""
    
    // Temp storage for onboarding flow
    var tempOnboardingData: (id: String, first: String, last: String, email: String)?
    var currentNonce: String?
    
    static let demoUser = UserProfile(
        id: "demo-user-001",
        firstName: "Demo",
        lastName: "Student",
        email: "demo@classlly.app",
        schoolName: "University of Example",
        gradeLevel: "Bachelor's Degree",
        major: "Computer Science",
        academicYear: "2024-2025"
    )
    
    init() {
        // If we have a stored ID, we are theoretically authenticated
        self.isAuthenticated = !storedUserId.isEmpty
    }
    
    // MARK: - Auto Login
    func loadUser(context: ModelContext) {
        guard !storedUserId.isEmpty else { return }
        
        if storedUserId == AuthenticationManager.demoUser.id {
            self.currentUser = AuthenticationManager.demoUser
            return
        }
        
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.id == storedUserId }
        )
        
        do {
            let results = try context.fetch(descriptor)
            if let user = results.first {
                self.currentUser = user
                self.isAuthenticated = true
            } else {
                // ID exists but user not found in DB (maybe deleted?)
                // You could handle logout here if needed
            }
        } catch {
            print("Failed to fetch user: \(error)")
        }
    }
    
    // MARK: - Sign In Flow
    func handleSignInWithApple(result: Result<ASAuthorization, Error>, context: ModelContext) {
        isLoading = true
        
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                processAppleIDCredential(appleIDCredential, context: context)
            }
        case .failure(let error):
            isLoading = false
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
    }
    
    private func processAppleIDCredential(_ credential: ASAuthorizationAppleIDCredential, context: ModelContext) {
        let userIdentifier = credential.user
        let firstName = credential.fullName?.givenName ?? ""
        let lastName = credential.fullName?.familyName ?? ""
        let email = credential.email ?? ""
        
        // 1. Check if user exists in DB
        let descriptor = FetchDescriptor<UserProfile>(predicate: #Predicate { $0.id == userIdentifier })
        
        if let existingUser = try? context.fetch(descriptor).first {
            // User exists -> Log in
            self.currentUser = existingUser
            self.storedUserId = userIdentifier // Save persistence
            self.isAuthenticated = true
            self.requiresOnboarding = false
        } else {
            // New User -> Go to Onboarding
            self.tempOnboardingData = (userIdentifier, firstName, lastName, email)
            self.requiresOnboarding = true
        }
        self.isLoading = false
    }
    
    func completeProfileSetup(
        firstName: String, lastName: String, schoolName: String,
        gradeLevel: String, major: String, academicYear: String,
        context: ModelContext
    ) {
        guard let temp = tempOnboardingData else { return }
        
        let newUser = UserProfile(
            id: temp.id,
            firstName: firstName,
            lastName: lastName,
            email: temp.email,
            schoolName: schoolName,
            gradeLevel: gradeLevel,
            major: major,
            academicYear: academicYear
        )
        
        context.insert(newUser)
        try? context.save()
        
        self.currentUser = newUser
        self.storedUserId = temp.id // Save persistence
        self.isAuthenticated = true
        self.requiresOnboarding = false
        self.universityNameForOnboarding = schoolName
    }
    
    func signInAsDemoUser() {
        self.currentUser = AuthenticationManager.demoUser
        self.storedUserId = AuthenticationManager.demoUser.id
        self.isAuthenticated = true
        self.requiresOnboarding = false
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
        storedUserId = "" // Clear persistence
        requiresOnboarding = false
    }
    
    // MARK: - Crypto Helpers (Required for Apple Sign In)
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess { fatalError("Unable to generate nonce") }
                return random
            }
            randoms.forEach { random in
                if remainingLength == 0 { return }
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
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
