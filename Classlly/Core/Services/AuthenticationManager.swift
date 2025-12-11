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
    
    func handleSignInWithApple(result: Result<ASAuthorization, Error>, modelContext: ModelContext) {
        // (Add Apple Sign In Logic here if needed, or keep empty for now to fix compile errors)
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
    func completeStickyOnboarding() {}
}
