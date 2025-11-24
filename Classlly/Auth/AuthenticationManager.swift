import SwiftUI
import AuthenticationServices
import CryptoKit
import Combine
import SwiftData

class AuthenticationManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var requiresOnboarding: Bool = false
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
        // Auth check logic relies on checkAuthentication(in:) called from views
    }
    
    // MARK: - SwiftData Auth Check
    @MainActor
    func checkAuthentication(in context: ModelContext) {
        let descriptor = FetchDescriptor<UserProfile>()
        do {
            if let user = try context.fetch(descriptor).first {
                self.currentUser = user
                self.isAuthenticated = true
                if user.id == AuthenticationManager.demoUser.id {
                    self.hasCompletedOnboarding = true
                    self.requiresOnboarding = false
                }
            }
        } catch {
            print("Auth check failed: \(error)")
        }
    }
    
    // MARK: - Sign In Methods
    
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
        
        // FIX: Added profileImageData: nil
        let tempUser = UserProfile(
            id: userIdentifier,
            firstName: firstName.isEmpty ? "Student" : firstName,
            lastName: lastName.isEmpty ? "Name" : lastName,
            email: email.isEmpty ? nil : email,
            schoolName: "",
            gradeLevel: "",
            major: nil,
            academicYear: "",
            profileImageData: nil
        )
        
        self.currentUser = tempUser
        self.isLoading = false
    }
    
    @MainActor
    func signInAsDemoUser(modelContext: ModelContext) {
        try? modelContext.delete(model: UserProfile.self)
        
        let demo = AuthenticationManager.demoUser
        modelContext.insert(demo)
        
        self.currentUser = demo
        self.isAuthenticated = true
        self.hasCompletedOnboarding = true
        self.requiresOnboarding = false
        
        generateSampleData(in: modelContext)
    }
    
    @MainActor
    func completeProfileSetup(profile: UserProfile, context: ModelContext) {
        context.insert(profile)
        self.currentUser = profile
        self.isAuthenticated = true
        self.universityNameForOnboarding = profile.schoolName
        try? context.save()
    }
    
    @MainActor
    func signOut(context: ModelContext) {
        self.isAuthenticated = false
        self.currentUser = nil
        self.hasCompletedOnboarding = false
        self.universityNameForOnboarding = ""
        
        try? context.delete(model: UserProfile.self)
        try? context.save()
    }
    
    // MARK: - Helpers
    
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
    
    // MARK: - Sample Data
    func generateSampleData(in context: ModelContext) {
        let descriptor = FetchDescriptor<Subject>()
        if let count = try? context.fetchCount(descriptor), count > 0 {
            return
        }

        let mathSubject = Subject(
            title: "Calculus II",
            courseTeacher: "Dr. Smith",
            courseClassroom: "Room 101",
            courseDays: [2, 4],
            courseFrequency: .weekly,
            seminarTeacher: "TA Johnson",
            seminarClassroom: "Lab A",
            seminarDays: [5],
            seminarFrequency: .weekly
        )
        
        let historySubject = Subject(
            title: "Modern History",
            courseTeacher: "Prof. Brown",
            courseClassroom: "Auditorium B",
            courseDays: [3],
            courseFrequency: .weekly,
            seminarTeacher: "Ms. Davis",
            seminarClassroom: "Room 204",
            seminarDays: [5],
            seminarFrequency: .biweeklyOdd
        )
        
        context.insert(mathSubject)
        context.insert(historySubject)
        
        let task1 = StudyTask(
            title: "Complete Calculus Problem Set",
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            priority: .high,
            subject: mathSubject,
            isFlagged: true,
            notes: "Complete problems 1-10 in Chapter 3."
        )
        
        let task2 = StudyTask(
            title: "Read Chapter 4",
            dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
            priority: .medium,
            subject: historySubject,
            isFlagged: false,
            notes: "Take notes on key figures."
        )
        
        context.insert(task1)
        context.insert(task2)
        
        let grade1 = GradeEntry(
            date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            grade: 9.0,
            weight: 30.0,
            description: "Midterm Exam"
        )
        grade1.subject = mathSubject
        context.insert(grade1)
    }
}
