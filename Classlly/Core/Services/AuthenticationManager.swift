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
            id: "demo-user-id", email: "demo@classlly.com",
            firstName: "Demo", lastName: "Student",
            schoolName: "Demo University", gradeLevel: "12", academicYear: "2025-2026"
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
            id: UUID().uuidString,
            email: "newuser@test.com",
            firstName: "Fresh",
            lastName: "Student",
            schoolName: "My School",
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
        // Placeholder for Apple Sign In
    }
    
    func signOut(modelContext: ModelContext) {
        DispatchQueue.main.async { self.currentUser = nil; self.isAuthenticated = false }
    }
    
    func completeProfileSetup(profile: StudentProfile, modelContext: ModelContext) {
        modelContext.insert(profile)
        DispatchQueue.main.async { self.currentUser = profile; self.isAuthenticated = true }
    }
    
    func randomNonceString(length: Int = 32) -> String { return "nonce" }
    func sha256(_ input: String) -> String { return input }
}
