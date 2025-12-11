import Foundation
import SwiftData

@Model
final class StudentProfile {
    @Attribute(.unique) var id: String = ""
    var email: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var schoolName: String = ""
    var gradeLevel: String = ""
    var major: String? = nil
    var academicYear: String = ""
    @Attribute(.externalStorage) var profileImageData: Data? = nil
    
    init(id: String,
         email: String,
         firstName: String,
         lastName: String,
         schoolName: String = "",
         gradeLevel: String = "",
         major: String? = nil,
         academicYear: String = "",
         profileImageData: Data? = nil) {
        
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
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
