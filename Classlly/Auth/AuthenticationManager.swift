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
        checkExistingAuthentication()
        
        if self.isAuthenticated && !self.hasCompletedOnboarding && self.currentUser?.id != AuthenticationManager.demoUser.id {
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
        self.universityNameForOnboarding = profile.schoolName
        
        if !self.hasCompletedOnboarding {
            self.requiresOnboarding = true
        }
        
        if let userData = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
    }
    
    func signInAsDemoUser(modelContext: ModelContext? = nil) {
        self.currentUser = AuthenticationManager.demoUser
        self.isAuthenticated = true
        
        self.hasCompletedOnboarding = true
        self.requiresOnboarding = false
        
        if let userData = try? JSONEncoder().encode(self.currentUser) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
        
        if let context = modelContext {
            generateSampleData(in: context)
        }
    }
    
    private func generateSampleData(in context: ModelContext) {
        let descriptor = FetchDescriptor<Subject>()
        if let count = try? context.fetchCount(descriptor), count > 0 {
            return
        }
        
        let mathSubject = Subject(
            title: "Mathematics 101",
            courseTeacher: "Dr. Alan Smith",
            courseClassroom: "Room 304",
            courseStartTime: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!,
            courseEndTime: Calendar.current.date(bySettingHour: 11, minute: 30, second: 0, of: Date())!,
            courseDays: [2, 4],
            courseFrequency: .weekly,
            seminarTeacher: "Mr. T. Assistant",
            seminarClassroom: "Lab 2",
            seminarStartTime: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date())!,
            seminarEndTime: Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date())!,
            seminarDays: [5],
            seminarFrequency: .weekly
        )
        
        let historySubject = Subject(
            title: "World History",
            courseTeacher: "Prof. Sarah Jones",
            courseClassroom: "Lecture Hall A",
            courseStartTime: Calendar.current.date(bySettingHour: 13, minute: 0, second: 0, of: Date())!,
            courseEndTime: Calendar.current.date(bySettingHour: 14, minute: 30, second: 0, of: Date())!,
            courseDays: [3, 5],
            courseFrequency: .weekly,
            seminarTeacher: "",
            seminarClassroom: "",
            seminarDays: [],
            seminarFrequency: .weekly
        )
        
        context.insert(mathSubject)
        context.insert(historySubject)
        
        let task1 = StudyTask(
            title: "Complete Calculus Problem Set",
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            priority: .high,
            subject: mathSubject,
            isFlagged: true,
            notes: "Complete problems 1-10 in Chapter 3. Focus on derivatives." // NEW
        )
        
        let task2 = StudyTask(
            title: "Read Chapter 4: The Industrial Revolution",
            dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
            priority: .medium,
            subject: historySubject,
            isFlagged: false,
            notes: "Take notes on key figures and economic impacts." // NEW
        )
        
        let task3 = StudyTask(
            title: "Buy new graphing calculator batteries",
            dueDate: Date(),
            priority: .low,
            subject: nil,
            isFlagged: false,
            notes: "Model AAA, get a 4-pack." // NEW
        )
        
        context.insert(task1)
        context.insert(task2)
        context.insert(task3)
        
        let grade1 = GradeEntry(
            date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            grade: 9.0,
            weight: 30.0,
            description: "Midterm Exam"
        )
        grade1.subject = mathSubject
        context.insert(grade1)
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
        
        self.hasCompletedOnboarding = false
        self.universityNameForOnboarding = ""
        
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
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
