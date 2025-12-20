import SwiftUI
import Combine
import SwiftData

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: StudentProfile?
    
    private let userDefaults = UserDefaults.standard
    private let authKey = "isAuthenticated"
    
    private init() {
        self.isAuthenticated = userDefaults.bool(forKey: authKey)
    }
    
    func signIn() {
        // Logic for real Apple/Google sign in would go here
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
    
    // ✅ Handle "Sticky" Onboarding Completion
    func completeStickyOnboarding(modelContext: ModelContext) {
        print("🚀 Completing Sticky Onboarding...")
        finalizeOnboarding(modelContext: modelContext)
    }
    
    // ✅ NEW: Handle "Standard" Profile Setup Completion
    func completeProfileSetup(modelContext: ModelContext) {
        print("✅ Completing Standard Profile Setup...")
        finalizeOnboarding(modelContext: modelContext)
    }
    
    // Shared Logic to Save & Authenticate
    private func finalizeOnboarding(modelContext: ModelContext) {
        // 1. If no user exists yet (skipped sign in), create a default local profile
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
            print("👤 Default local user created.")
        }
        
        // 2. Save any pending changes
        try? modelContext.save()
        
        // 3. Mark as authenticated to transition to MainTabView
        isAuthenticated = true
        userDefaults.set(true, forKey: authKey)
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
        userDefaults.set(false, forKey: authKey)
    }
}
