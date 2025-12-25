import Foundation
import AuthenticationServices
import Observation

// Simple struct to hold session data
struct UserSession: Sendable, Codable {
    let uid: String
    let email: String?
    let fullName: String?
    let isAnonymous: Bool
}

@Observable
class AuthenticationManager {
    var userSession: UserSession?
    var hasCompletedOnboarding: Bool = false
    
    // Constant ID for consistency across the app
    static let demoUserID = "demo-user-001"
    
    // Derived state
    var isAuthenticated: Bool {
        userSession != nil
    }
    
    init() {
        // Load state from UserDefaults on launch
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        if let savedData = UserDefaults.standard.data(forKey: "userSession"),
           let session = try? JSONDecoder().decode(UserSession.self, from: savedData) {
            self.userSession = session
        }
    }
    
    // MARK: - Auth Actions
    
    func signInWithApple() async throws {
        // Simulation of Apple Auth
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // In a real app, you get this data from ASAuthorizationController
        let newSession = UserSession(
            uid: UUID().uuidString,
            email: "student@classlly.com",
            fullName: "Apple User",
            isAnonymous: false
        )
        updateSession(newSession)
    }
    
    func signInAsDemoUser() {
        print("👤 Signing in as Demo User...")
        let demoSession = UserSession(
            uid: Self.demoUserID, // Use the static constant
            email: "demo@classlly.com",
            fullName: "Demo Student",
            isAnonymous: true
        )
        updateSession(demoSession)
    }
    
    func signOut() {
        userSession = nil
        UserDefaults.standard.removeObject(forKey: "userSession")
    }
    
    // MARK: - Debug / Dev Tools
    
    func debugReset() {
        print("⚠️ Resetting Auth State...")
        signOut()
        hasCompletedOnboarding = false
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    // MARK: - Private Helpers
    private func updateSession(_ session: UserSession) {
        self.userSession = session
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: "userSession")
        }
    }
}
