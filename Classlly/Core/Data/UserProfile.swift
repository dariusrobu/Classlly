import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var email: String? = nil
    var schoolName: String = ""
    var gradeLevel: String = ""
    var major: String? = nil
    var academicYear: String = ""
    var profileImageData: Data? = nil
    
    init(
        id: String,
        firstName: String,
        lastName: String,
        email: String? = nil,
        schoolName: String = "",
        gradeLevel: String = "",
        major: String? = nil,
        academicYear: String = "",
        profileImageData: Data? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.schoolName = schoolName
        self.gradeLevel = gradeLevel
        self.major = major
        self.academicYear = academicYear
        self.profileImageData = profileImageData
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
