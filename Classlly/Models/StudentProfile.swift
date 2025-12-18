import Foundation
import SwiftData

@Model
final class StudentProfile {
    // ✅ FIX: CloudKit requires default values for ALL properties
    var id: UUID = UUID()
    var name: String = ""
    var email: String = ""
    var university: String = ""
    var major: String = ""
    var gradeLevel: String = ""
    var academicYear: String = ""
    var joinedDate: Date = Date()
    
    @Attribute(.externalStorage) var profileImageData: Data? = nil
    
    init(
        name: String,
        email: String,
        university: String = "",
        major: String = "",
        gradeLevel: String = "",
        academicYear: String = "",
        profileImageData: Data? = nil
    ) {
        self.id = UUID()
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
