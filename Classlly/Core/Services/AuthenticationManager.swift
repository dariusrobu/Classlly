import Foundation
import SwiftUI
import Combine
import SwiftData
import AuthenticationServices

class AuthenticationManager: ObservableObject {
    @Published var currentUser: StudentProfile?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var universityNameForOnboarding = ""
    @Published var requiresOnboarding = false
    
    // New state for driving the UI
    @Published var showingOnboarding = false
    
    var currentNonce: String?
    static let shared = AuthenticationManager()
    private init() {}
    
    func signInAsDemoUser() {
        let demoUser = StudentProfile(
            name: "Demo Student",
            email: "demo@classlly.com",
            university: "Demo University",
            major: "Computer Science",
            gradeLevel: "12",
            academicYear: "2025-2026"
        )
        DispatchQueue.main.async {
            self.currentUser = demoUser
            self.isAuthenticated = true
        }
    }
    
    func startNewUserOnboarding() {
        // Trigger the full screen cover in SignInView
        DispatchQueue.main.async {
            self.showingOnboarding = true
        }
    }
    
    func completeStickyOnboarding(modelContext: ModelContext) {
        // 1. Create a fresh user profile for the new user
        let newUser = StudentProfile(
            name: "Fresh Student",
            email: "newuser@test.com",
            university: "My School",
            major: "Undeclared",
            gradeLevel: "Freshman",
            academicYear: "2024-2025"
        )
        
        // 2. Insert into database
        modelContext.insert(newUser)
        
        // 3. Update State to Log In and Dismiss Onboarding
        DispatchQueue.main.async {
            self.currentUser = newUser
            self.isAuthenticated = true
            self.showingOnboarding = false
        }
    }
    
    func handleSignInWithApple(result: Result<ASAuthorization, Error>, modelContext: ModelContext) {
        // Placeholder for Apple Sign In logic
        // This would typically involve decoding the result, finding/creating a user, and setting currentUser
    }
    
    func signOut() {
        DispatchQueue.main.async {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    // Helper to insert a profile externally if needed
    func completeProfileSetup(profile: StudentProfile, modelContext: ModelContext) {
        modelContext.insert(profile)
        DispatchQueue.main.async {
            self.currentUser = profile
            self.isAuthenticated = true
        }
    }
    
    // Apple Sign In Helpers
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// Add CryptoKit for SHA256
import CryptoKit
