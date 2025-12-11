import Foundation

struct StudentProfile: Codable, Identifiable, Equatable {
    let id: String
    var email: String
    var fullName: String
    var gradeLevel: Int
    // Add other fields as needed
    
    // explicit init to avoid inference issues
    init(id: String, email: String, fullName: String, gradeLevel: Int) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.gradeLevel = gradeLevel
    }
}
