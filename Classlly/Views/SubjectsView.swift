import SwiftUI
import SwiftData

struct SubjectsView: View {
    @Query(sort: \Subject.title) var subjects: [Subject]
    @EnvironmentObject var themeManager: AppTheme
    
    @State private var showingAddSubject = false
    @Environment(\.colorScheme) var colorScheme
    
    public init() {}

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(subjects) { subject in
                    NavigationLink(destination: SubjectDetailView(subject: subject)) {
                        SubjectCard(subject: subject)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
        .navigationTitle("Subjects")
        .navigationBarTitleDisplayMode(.inline)
        // Ensure background is transparent so ContentView's background shows through
        // (Standard Grey in Normal Mode, Black/Neon in Gamified Mode)
        .background(Color.clear)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddSubject = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        // Only use accent color in Gamified Mode, otherwise standard Blue
                        .foregroundColor(themeManager.isGamified ? themeManager.selectedTheme.accentColor : .themePrimary)
                }
            }
        }
        .sheet(isPresented: $showingAddSubject) {
            AddSubjectView()
        }
    }
}

struct SubjectCard: View {
    let subject: Subject
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var themeManager: AppTheme
    
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
                        // UPDATED: Only use Neon Accent in Gamified Mode, else Standard Blue
                        color: themeManager.isGamified ? themeManager.selectedTheme.accentColor : .themePrimary
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
                StatPill(icon: "star", value: "\(subject.gradeHistory.count)", label: "Grades")
            }
        }
        .padding()
        // Apply the smart modifier (Glass in Gamified, Solid in Standard)
        .gamifiedCard(themeManager: themeManager)
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var themeManager: AppTheme
    
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
        // UPDATED: Conditional Background
        .background {
            if themeManager.isGamified {
                Rectangle().fill(.thinMaterial)
            } else {
                Rectangle().fill(Color.adaptiveTertiaryBackground)
            }
        }
        .cornerRadius(8)
    }
}

struct GradeBadge: View {
    let grade: Double
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var themeManager: AppTheme
    
    private var gradeColor: Color {
        // Only use neon accent for high grades IF gamified mode is on
        if themeManager.isGamified && grade >= 8.5 {
            return themeManager.selectedTheme.accentColor
        }
        
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
    @Environment(\.colorScheme) var colorScheme
    
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
    @Environment(\.colorScheme) var colorScheme
    
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
