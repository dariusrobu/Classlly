import SwiftUI
import SwiftData

struct SubjectsView: View {
    @Query(sort: \Subject.title) var subjects: [Subject]
    @State private var showingAddSubject = false
    @AppStorage("isGamified") private var isGamified = false
    @Environment(\.colorScheme) var colorScheme
    
    public init() {}

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(subjects) { subject in
                        NavigationLink(value: subject) {
                            if isGamified {
                                GamifiedSubjectCard(subject: subject)
                            } else {
                                MinimalSubjectCard(subject: subject)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("Subjects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSubject = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(isGamified ? .themePrimary : .primary)
                    }
                }
            }
            .navigationDestination(for: Subject.self) { subject in
                SubjectDetailView(subject: subject)
            }
            .sheet(isPresented: $showingAddSubject) {
                AddSubjectView()
            }
        }
    }
}

// MARK: - Modern Minimalist Card (Gamified OFF)
struct MinimalSubjectCard: View {
    let subject: Subject
    
    var body: some View {
        HStack(spacing: 16) {
            // 1. Color Strip Identifier
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.themePrimary)
                .frame(width: 4, height: 50)
            
            // 2. Main Info
            VStack(alignment: .leading, spacing: 4) {
                Text(subject.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(subject.courseDaysString.prefix(3)) // Short day (Mon)
                    Text("•")
                    Text(subject.courseTimeString)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 3. Functional Stats (Grade & Attendance)
            HStack(spacing: 12) {
                if let grade = subject.currentGrade {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(String(format: "%.1f", grade))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(grade >= 5 ? .primary : .themeError)
                        Text("Grade")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    }
                }
                
                // Attendance Ring
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 3)
                        .frame(width: 36, height: 36)
                    
                    Circle()
                        .trim(from: 0, to: subject.attendanceRate)
                        .stroke(Color.themeSuccess, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 36, height: 36)
                    
                    Text("\(Int(subject.attendanceRate * 100))%")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Gamified Card (Gamified ON)
struct GamifiedSubjectCard: View {
    let subject: Subject
    
    var level: Int {
        let xp = (subject.attendedClasses * 50) + Int((subject.currentGrade ?? 0) * 100)
        return (xp / 500) + 1
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Level Hexagon
            ZStack {
                Image(systemName: "hexagon.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.themeSecondary)
                    .shadow(color: .themeSecondary.opacity(0.5), radius: 4)
                
                VStack(spacing: 0) {
                    Text("LVL")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                    Text("\(level)")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                }
            }
            
            // Info & XP Bar
            VStack(alignment: .leading, spacing: 4) {
                Text(subject.title)
                    .font(.headline)
                    .bold()
                    .foregroundColor(.themeTextPrimary)
                
                HStack(spacing: 4) {
                    // XP Bar
                    Capsule()
                        .fill(Color.themeSurface)
                        .frame(height: 6)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(LinearGradient(colors: [.themeSuccess, .themeAccent], startPoint: .leading, endPoint: .trailing))
                                .frame(width: 100 * subject.attendanceRate)
                        }
                    
                    Text("\(Int(subject.attendanceRate * 100))%")
                        .font(.caption2)
                        .foregroundColor(.themeTextSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.themeBackground.opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(LinearGradient(colors: [.themePrimary.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing), lineWidth: 1)
        )
    }
}
