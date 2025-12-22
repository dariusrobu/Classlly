import SwiftUI
import SwiftData

// Mock model for the import process (intermediate step)
struct ImportedCourse: Identifiable {
    let id = UUID()
    var title: String
    var teacher: String
    var room: String
    var dayOfWeek: Int // 1-7
    var startTime: Date
    var endTime: Date
    var isOddWeek: Bool? // nil = every week, true = odd, false = even
    var type: String // "Course" or "Seminar"
}

struct ScheduleImportReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // In a real app, this would be passed from the parser
    // Here is mock data for demonstration
    @State private var importedCourses: [ImportedCourse] = [
        ImportedCourse(title: "Mathematics", teacher: "Dr. Smith", room: "A101", dayOfWeek: 2, startTime: Date(), endTime: Date().addingTimeInterval(5400), isOddWeek: nil, type: "Course"),
        ImportedCourse(title: "Physics", teacher: "Prof. Doe", room: "Lab 3", dayOfWeek: 3, startTime: Date(), endTime: Date().addingTimeInterval(7200), isOddWeek: true, type: "Course")
    ]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Review the courses found in your schedule. Uncheck any you don't want to import.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                ForEach($importedCourses) { $course in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(course.title)
                                .font(.headline)
                            Text("\(course.type) • \(course.teacher) • \(course.room)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let isOdd = course.isOddWeek {
                            Text(isOdd ? "Odd Week" : "Even Week")
                                .font(.caption2)
                                .padding(4)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        } else {
                            Text("Weekly")
                                .font(.caption2)
                                .padding(4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .navigationTitle("Import Review")
            .toolbar {
                Button("Import All") {
                    saveAll()
                }
            }
        }
    }
    
    private func saveAll() {
        for course in importedCourses {
            // Determine Frequency
            let frequency: ClassFrequency
            if let isOdd = course.isOddWeek {
                frequency = isOdd ? .biweeklyOdd : .biweeklyEven
            } else {
                frequency = .weekly
            }
            
            // Create the Subject
            let newSubject = Subject(
                title: course.title,
                colorHex: "007AFF", // Default color
                credits: 0, // Using standard credits property
                
                // Course Details
                courseTeacher: course.teacher,
                courseClassroom: course.room,
                courseDays: [course.dayOfWeek],
                courseFrequency: frequency, // ✅ Updated frequency logic
                courseStartTime: course.startTime,
                courseEndTime: course.endTime,
                
                // Seminar Details (Default to empty)
                hasSeminar: false
            )
            
            modelContext.insert(newSubject)
        }
        dismiss()
    }
}
