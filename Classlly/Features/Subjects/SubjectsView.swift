import SwiftUI
import SwiftData

struct SubjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var themeManager: AppTheme
    @AppStorage("isGamifiedMode") private var isGamifiedMode = false
    @Query(sort: \Subject.title) var subjects: [Subject]
    @State private var showingAddSubject = false
    
    public init() {}

    var body: some View {
        // Navigation is handled by ContentView/Sidebar
        ScrollView {
            if subjects.isEmpty {
                EmptySubjectState(isGamified: isGamifiedMode)
                    .padding(.top, 50)
            } else {
                LazyVStack(spacing: isGamifiedMode ? 20 : 16) {
                    ForEach(subjects) { subject in
                        NavigationLink(destination: SubjectDetailView(subject: subject)) {
                            if isGamifiedMode {
                                GamifiedSubjectCard(subject: subject, themeColor: themeManager.selectedTheme.accentColor)
                            } else {
                                SubjectCard(subject: subject)
                            }
                        }.buttonStyle(PlainButtonStyle())
                    }
                }.padding()
            }
        }
        .background(Color.themeBackground)
        .navigationTitle("Subjects")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddSubject = true }) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 22, weight: .medium)).foregroundColor(isGamifiedMode ? themeManager.selectedTheme.accentColor : .themePrimary)
                }
            }
        }
        .sheet(isPresented: $showingAddSubject) { AddSubjectView() }
    }
}

// MARK: - 1. Gamified Subject Card
struct GamifiedSubjectCard: View {
    let subject: Subject
    let themeColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subject.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.caption)
                        Text(subject.courseTeacher)
                            .font(.subheadline)
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                if let grade = subject.currentGrade {
                    Text(String(format: "%.1f", grade))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(themeColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .cornerRadius(12)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Info Grid
            HStack(spacing: 20) {
                Label {
                    Text("\(Int(subject.attendanceRate * 100))%")
                        .fontWeight(.semibold)
                } icon: {
                    Image(systemName: "chart.bar.fill")
                }
                
                Label {
                    Text(subject.courseClassroom)
                        .fontWeight(.semibold)
                } icon: {
                    Image(systemName: "mappin.circle.fill")
                }
                
                Spacer()
                
                Text(subject.courseFrequencyString)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
            }
            .foregroundColor(.white)
            .font(.callout)
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [themeColor, themeColor.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .shadow(color: themeColor.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 2. Standard Subject Card
struct SubjectCard: View {
    let subject: Subject
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subject.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.themeTextPrimary)
                    Text(subject.courseTeacher)
                        .font(.subheadline)
                        .foregroundColor(.themeTextSecondary)
                }
                Spacer()
                if let grade = subject.currentGrade {
                    GradeBadge(grade: grade)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(icon: "clock", text: "\(subject.courseDaysString) \(subject.courseTimeString)")
                InfoRow(icon: "mappin.circle", text: subject.courseClassroom)
            }
            
            HStack(spacing: 16) {
                ProgressIndicator(
                    title: "Attendance",
                    value: subject.attendanceRate,
                    color: .themeSuccess
                )
                
                if let grade = subject.currentGrade {
                    ProgressIndicator(
                        title: "Grade",
                        value: grade / 10.0,
                        color: .themePrimary
                    )
                }
                
                ProgressIndicator(
                    title: "Classes",
                    value: Double(subject.totalClasses) / 20.0,
                    color: .themeWarning
                )
            }
            
            HStack(spacing: 12) {
                StatPill(icon: "checkmark.circle", value: "\(subject.attendedClasses)", label: "Present")
                StatPill(icon: "xmark.circle", value: "\(subject.totalClasses - subject.attendedClasses)", label: "Absent")
                // Handle optional array safely
                StatPill(icon: "star", value: "\((subject.gradeHistory ?? []).count)", label: "Grades")
            }
        }
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.adaptiveBorder.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - 3. Helpers

struct EmptySubjectState: View {
    let isGamified: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 50))
                .foregroundColor(isGamified ? .gray : .themeTextSecondary)
            
            Text("No Subjects Yet")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.themeTextPrimary)
            
            Text("Add your first subject to start tracking grades and attendance.")
                .font(.subheadline)
                .foregroundColor(.themeTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(.themeTextSecondary)
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.themeTextPrimary)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.themeTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.adaptiveTertiaryBackground)
        .cornerRadius(8)
    }
}

struct GradeBadge: View {
    let grade: Double
    
    private var gradeColor: Color {
        switch grade {
        case 9...10: return .themeSuccess
        case 7..<9: return .themePrimary
        case 5..<7: return .themeWarning
        default: return .themeError
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%.1f", grade))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Text("/10")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(gradeColor)
        .cornerRadius(8)
    }
}

struct ProgressIndicator: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.themeTextSecondary)
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(color.opacity(0.2))
                    .frame(height: 6)
                    .cornerRadius(3)
                
                Rectangle()
                    .fill(color)
                    .frame(width: CGFloat(max(0, min(value, 1.0))) * 60, height: 6)
                    .cornerRadius(3)
            }
            .frame(width: 60)
            
            Text("\(Int(value * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.themeTextSecondary)
                .frame(width: 16)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.themeTextPrimary)
            Spacer()
        }
    }
}
