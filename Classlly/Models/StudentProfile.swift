import SwiftUI
import SwiftData

@Model
final class StudentProfile {
    var id: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var email: String? = nil
    var schoolName: String = ""
    var gradeLevel: String = ""
    var major: String? = nil
    var academicYear: String = ""
    
    init(id: String, firstName: String, lastName: String, email: String? = nil, schoolName: String = "", gradeLevel: String = "", major: String? = nil, academicYear: String = "") {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.schoolName = schoolName
        self.gradeLevel = gradeLevel
        self.major = major
        self.academicYear = academicYear
    }
    
    func toUserProfile() -> UserProfile {
        UserProfile(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            schoolName: schoolName,
            gradeLevel: gradeLevel,
            major: major,
            academicYear: academicYear,
            profileImageData: nil
        )
    }
}
