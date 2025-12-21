import SwiftUI
import Combine
import SwiftData

@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    // MARK: - State Properties
    @Published var isAuthenticated: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    @Published var hasSeenCarousel: Bool = false
    @Published var currentUser: StudentProfile?
    
    // MARK: - Persistence Keys
    private let userDefaults = UserDefaults.standard
    private let authKey = "isAuthenticated"
    private let onboardingKey = "hasCompletedOnboarding"
    private let carouselKey = "hasSeenCarousel"
    
    init() {
        self.isAuthenticated = userDefaults.bool(forKey: authKey)
        self.hasCompletedOnboarding = userDefaults.bool(forKey: onboardingKey)
        self.hasSeenCarousel = userDefaults.bool(forKey: carouselKey)
    }
    
    // MARK: - Actions
    
    func completeCarousel() {
        print("✅ Carousel Completed")
        hasSeenCarousel = true
        userDefaults.set(true, forKey: carouselKey)
    }
    
    func signIn(with user: StudentProfile? = nil) {
        if let user = user {
            self.currentUser = user
        }
        isAuthenticated = true
        userDefaults.set(true, forKey: authKey)
        print("✅ User Signed In")
    }
    
    func completeProfileSetup(modelContext: ModelContext) {
        print("🚀 Completing Profile Setup...")
        
        // 1. Ensure we have a valid user
        if currentUser == nil {
            let defaultUser = StudentProfile(name: "Student", email: "user@classlly.app")
            modelContext.insert(defaultUser)
            self.currentUser = defaultUser
        }
        
        // 2. Persist Changes to Disk IMMEDIATELY
        do {
            try modelContext.save()
            print("💾 Profile Data Saved Successfully")
        } catch {
            print("❌ Failed to save profile: \(error.localizedDescription)")
        }
        
        // 3. Update State Flags
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: onboardingKey)
        
        // 4. Force UI Refresh
        // This ensures views observing the manager (like MainTabView) redraw with the new name
        objectWillChange.send()
    }
    
    func signOut() {
        print("👋 Signing Out")
        isAuthenticated = false
        currentUser = nil
        hasCompletedOnboarding = false
        // We typically keep hasSeenCarousel true so they don't see the tutorial again
        
        userDefaults.set(false, forKey: authKey)
        userDefaults.set(false, forKey: onboardingKey)
    }
    
    func debugReset() {
        print("⚠️ Executing Debug Reset...")
        isAuthenticated = false
        currentUser = nil
        hasCompletedOnboarding = false
        hasSeenCarousel = false
        
        userDefaults.removeObject(forKey: authKey)
        userDefaults.removeObject(forKey: onboardingKey)
        userDefaults.removeObject(forKey: carouselKey)
        userDefaults.synchronize()
    }
    
    // Demo Helper
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
        self.hasCompletedOnboarding = true // Demo users skip setup
        
        userDefaults.set(true, forKey: authKey)
        userDefaults.set(true, forKey: onboardingKey)
        
        return demoUser
    }
}
