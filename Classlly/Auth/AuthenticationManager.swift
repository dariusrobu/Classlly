import SwiftUI
import AuthenticationServices
import CryptoKit
import Combine
import SwiftData // Import SwiftData

class AuthenticationManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var requiresOnboarding: Bool = false
    @Published var universityNameForOnboarding: String = ""

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var currentNonce: String?
    
    static let demoUser = AppUser(
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
            self.universityNameForOnboarding = self.currentUser?.schoolName ?? ""
            self.requiresOnboarding = true
        }
    }
    
    private func checkExistingAuthentication() {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(AppUser.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    func handleSignInWithApple(result: Result<ASAuthorization, Error>) {
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
        let userIdentifier = credential.user
        let firstName = credential.fullName?.givenName ?? ""
        let lastName = credential.fullName?.familyName ?? ""
        let email = credential.email ?? ""
        
        let tempUser = AppUser(
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
    
    func completeProfileSetup(profile: AppUser) {
        self.currentUser = profile
        self.isAuthenticated = true
        self.universityNameForOnboarding = profile.schoolName
        
        if !self.hasCompletedOnboarding {
            self.requiresOnboarding = true
        }
        
        if let userData = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
    }
    
    // --- UPDATED: Accepts ModelContext to generate 3 Tasks & 3 Subjects ---
    @MainActor
    func signInAsDemoUser(modelContext: ModelContext? = nil) {
        self.currentUser = AuthenticationManager.demoUser
        self.isAuthenticated = true
        self.hasCompletedOnboarding = true
        self.requiresOnboarding = false
        
        if let userData = try? JSONEncoder().encode(self.currentUser) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
        
        // Generate Sample Data if context is provided
        if let context = modelContext {
            generateDemoData(context: context)
        }
    }
    
    @MainActor
    private func generateDemoData(context: ModelContext) {
        // Check if data already exists to avoid duplicates
        let descriptor = FetchDescriptor<Subject>()
        if let count = try? context.fetchCount(descriptor), count > 0 {
            return
        }

        // 1. Create 3 Subjects
        let mathSubject = Subject(
            title: "Advanced Calculus",
            courseTeacher: "Dr. Sarah Smith",
            courseClassroom: "Science Hall 101",
            courseDays: [2, 4], // Mon, Wed
            courseFrequency: .weekly,
            seminarTeacher: "John Doe",
            seminarClassroom: "Room 204",
            seminarDays: [5], // Thu
            seminarFrequency: .weekly
        )
        
        let csSubject = Subject(
            title: "Algorithms & Data",
            courseTeacher: "Prof. Alan Turing",
            courseClassroom: "Tech Center Lab 3",
            courseDays: [3, 5], // Tue, Thu
            courseFrequency: .weekly,
            seminarTeacher: "Grace Hopper",
            seminarClassroom: "Tech Center 101",
            seminarDays: [3], // Tue
            seminarFrequency: .biweeklyOdd
        )
        
        let physicsSubject = Subject(
            title: "Quantum Mechanics",
            courseTeacher: "Dr. Richard Feynman",
            courseClassroom: "Physics Wing 3B",
            courseDays: [1, 4], // Sun, Wed
            courseFrequency: .weekly,
            seminarTeacher: "Marie Curie",
            seminarClassroom: "Lab 4",
            seminarDays: [2], // Mon
            seminarFrequency: .biweeklyEven
        )
        
        context.insert(mathSubject)
        context.insert(csSubject)
        context.insert(physicsSubject)
        
        // 2. Create 3 Tasks linked to those subjects
        let task1 = StudyTask(
            title: "Complete Calculus Problem Set 4",
            dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()), // Due in 2 days
            priority: .high,
            subject: mathSubject,
            reminderTime: .dayBefore1,
            isFlagged: true
        )
        
        let task2 = StudyTask(
            title: "Implement Binary Search Tree",
            dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()), // Due in 5 days
            priority: .medium,
            subject: csSubject,
            reminderTime: .hourBefore1,
            isFlagged: false
        )
        
        let task3 = StudyTask(
            title: "Read 'QED' Chapter 1",
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), // Due tomorrow
            priority: .low,
            subject: physicsSubject,
            reminderTime: .none,
            isFlagged: false
        )
        
        context.insert(task1)
        context.insert(task2)
        context.insert(task3)
        
        // Save context
        try? context.save()
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
        self.hasCompletedOnboarding = false
        self.universityNameForOnboarding = ""
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    // MARK: - Crypto Helpers
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
                if errorCode != errSecSuccess { fatalError() }
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

// AppUser Struct
struct AppUser: Codable, Equatable {
    let id: String
    var firstName: String
    var lastName: String
    var email: String?
    var schoolName: String
    var gradeLevel: String
    var major: String?
    var academicYear: String
    var profileImageData: Data?
    
    var fullName: String { "\(firstName) \(lastName)" }
    static func == (lhs: AppUser, rhs: AppUser) -> Bool { return lhs.id == rhs.id }
}
