import Foundation
import SwiftData

@Model
final class StudentProfile {
    // ✅ FIX: Strictly removed @Attribute(.unique) to support CloudKit sync.
    var id: String = UUID().uuidString
    
    var name: String = ""
    var email: String = ""
    var university: String = ""
    var major: String = ""
    var gradeLevel: String = ""
    var academicYear: String = ""
    var joinedDate: Date = Date()
    
    @Attribute(.externalStorage) var profileImageData: Data? = nil
    
    init(
        id: String = UUID().uuidString,
        name: String,
        email: String,
        university: String = "",
        major: String = "",
        gradeLevel: String = "",
        academicYear: String = "",
        profileImageData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.university = university
        self.major = major
        self.gradeLevel = gradeLevel
        self.academicYear = academicYear
        self.profileImageData = profileImageData
        self.joinedDate = Date()
    }
}
