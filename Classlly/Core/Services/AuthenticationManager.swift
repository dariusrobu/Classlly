import SwiftUI
import Combine
import SwiftData

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated: Bool = false
    // ✅ ENSURE THIS IS @Published
    @Published var hasCompletedOnboarding: Bool = false
    @Published var currentUser: StudentProfile?
    
    private let userDefaults = UserDefaults.standard
    private let authKey = "isAuthenticated"
    private let onboardingKey = "hasCompletedOnboarding"
    
    init() {
        self.isAuthenticated = userDefaults.bool(forKey: authKey)
        self.hasCompletedOnboarding = userDefaults.bool(forKey: onboardingKey)
    }
    
    func signIn(with user: StudentProfile? = nil) {
        if let user = user {
            self.currentUser = user
        }
        isAuthenticated = true
        userDefaults.set(true, forKey: authKey)
    }
    
    func signInAsDemoUser() -> StudentProfile {
        let demoUser = StudentProfile(
            id: "demo_user_123",
            name: "Alex Carter",
            email: "alex@classlly.demo",
            university: "Tech University",
            major: "Computer Science",
            gradeLevel: "Sophomore",
            academicYear: "2024-2025"
        )
        
        self.currentUser = demoUser
        self.isAuthenticated = true
        userDefaults.set(true, forKey: authKey)
        
        return demoUser
    }
    
    func completeStickyOnboarding(modelContext: ModelContext) {
        print("🚀 Completing Sticky Onboarding... Proceeding to Sign In.")
        
        if currentUser == nil {
            let defaultUser = StudentProfile(
                id: UUID().uuidString,
                name: "Student",
                email: "",
                university: "",
                major: ""
            )
            modelContext.insert(defaultUser)
            self.currentUser = defaultUser
        }
        
        try? modelContext.save()
        
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: onboardingKey)
    }
    
    func completeProfileSetup(modelContext: ModelContext) {
        print("✅ Completing Standard Profile Setup...")
        isAuthenticated = true
        userDefaults.set(true, forKey: authKey)
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
        userDefaults.set(false, forKey: authKey)
    }
    
    func debugReset() {
        print("⚠️ Executing Debug Reset...")
        isAuthenticated = false
        currentUser = nil
        hasCompletedOnboarding = false // Reset this too
        
        userDefaults.removeObject(forKey: authKey)
        userDefaults.removeObject(forKey: onboardingKey)
        userDefaults.synchronize()
    }
}
