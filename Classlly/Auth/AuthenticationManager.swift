// File: Classlly/Auth/AuthenticationManager.swift
// Note: This file manages user authentication and profile data.
// It will be responsible for loading the user's profile.
// UserProfile is a Codable struct, not a SwiftData model,
// as it's managed by AppStorage/UserDefaults for the currently logged-in user.

import SwiftUI
import AuthenticationServices
import CryptoKit
import Combine

class AuthenticationManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var requiresOnboarding: Bool = false
    
    // --- NEW: This will pass the school name to the onboarding view ---
    @Published var universityNameForOnboarding: String = ""

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
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
        checkExistingAuthentication()
        
        if self.isAuthenticated && !self.hasCompletedOnboarding && self.currentUser?.id != AuthenticationManager.demoUser.id {
            // Get school name for a returning user who hasn't onboarded
            self.universityNameForOnboarding = self.currentUser?.schoolName ?? ""
            self.requiresOnboarding = true
        }
    }
    
    private func checkExistingAuthentication() {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(UserProfile.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    func handleSignInWithApple(result: Result<ASAuthorization, Error>) {
        // ... (This function is unchanged)
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                processAppleIDCredential(appleIDCredential)
            }
        case .failure(let error):
            isLoading = false
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
    }
    
    private func processAppleIDCredential(_ credential: ASAuthorizationAppleIDCredential) {
        // ... (This function is unchanged)
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
    
    func completeProfileSetup(profile: UserProfile) {
        self.currentUser = profile
        self.isAuthenticated = true
        
        // --- UPDATED ---
        // Save the school name to pass to the onboarding view
        self.universityNameForOnboarding = profile.schoolName
        
        if !self.hasCompletedOnboarding {
            self.requiresOnboarding = true
        }
        
        if let userData = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
    }
    
    func signInAsDemoUser() {
        // ... (This function is unchanged)
        self.currentUser = AuthenticationManager.demoUser
        self.isAuthenticated = true
        
        self.hasCompletedOnboarding = true
        self.requiresOnboarding = false
        
        if let userData = try? JSONEncoder().encode(self.currentUser) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
    }
    
    func signOut() {
        // ... (This function is unchanged)
        isAuthenticated = false
        currentUser = nil
        
        self.hasCompletedOnboarding = false
        self.universityNameForOnboarding = "" // Clear the name
        
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    // ... (Rest of the helper functions are unchanged) ...
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

// ... (UserProfile struct is unchanged) ...
// This struct is NOT a SwiftData @Model. It's stored in UserDefaults
// to represent the currently logged-in user's profile.
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
