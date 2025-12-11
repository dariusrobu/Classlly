import Foundation
import SwiftUI
import Combine // <-- ADD THIS

class AuthenticationManager: ObservableObject {
    @Published var currentUser: StudentProfile?
    
    static let shared = AuthenticationManager()
    
    private init() {}
    
    func fetchUserProfile(userID: String) async throws -> StudentProfile {
        // Mock delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let profile = StudentProfile(
            id: userID,
            email: "student@classlly.com",
            fullName: "Robudarius Student",
            gradeLevel: 10
        )
        
        await MainActor.run {
            self.currentUser = profile
        }
        
        return profile
    }
}
