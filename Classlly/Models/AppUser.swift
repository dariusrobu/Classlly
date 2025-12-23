import Foundation
import SwiftData

@Model
final class AppUser {
    // MARK: - CloudKit Requirements
    // 1. We CANNOT use @Attribute(.unique) with CloudKit.
    // 2. Non-optional properties MUST have a default value assigned on the declaration line.
    
    var id: String = UUID().uuidString
    var email: String?
    var fullName: String?
    var dateCreated: Date = Date()
    
    // Academic Info
    var universityName: String?
    var facultyName: String?
    var yearOfStudy: String?
    var group: String?
    
    // Settings / Meta
    var academicYear: String?
    var pushNotificationToken: String?
    
    // Computed Helpers
    var initials: String {
        guard let name = fullName, !name.isEmpty else { return "S" }
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: name) {
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        return String(name.prefix(1))
    }
    
    init(id: String, email: String? = nil, fullName: String? = nil) {
        self.id = id
        self.email = email
        self.fullName = fullName
        // dateCreated is already set to Date() by default, so we don't need to set it here
    }
}
