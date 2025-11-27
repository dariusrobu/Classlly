import SwiftUI

struct AppGuideView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: - Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Classlly Guide")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Master your academic life with these tips.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // MARK: - 1. Gamified Mode
                GuideSectionCard(
                    title: "Gamified Mode",
                    icon: "gamecontroller.fill",
                    color: .purple
                ) {
                    Text("Turn your studies into an RPG! Enable this in Settings to unlock:")
                    
                    GuideBullet(icon: "crown.fill", text: "Rank System: Your rank (e.g., Mythic, Legendary) is determined by your average grade.")
                    GuideBullet(icon: "bolt.fill", text: "XP (Experience): Earn XP by attending classes (50 XP) and getting grades (100 XP per entry).")
                    GuideBullet(icon: "paintpalette.fill", text: "Visual Overhaul: Transforms the app with vibrant gradients, card-style lists, and animated progress bars.")
                }
                
                // MARK: - 2. Managing Calendar
                GuideSectionCard(
                    title: "Managing Calendar",
                    icon: "calendar",
                    color: .blue
                ) {
                    Text("Keep your schedule perfectly synced with your university timeline.")
                    
                    GuideBullet(icon: "plus.square.fill", text: "Templates: Use built-in templates for supported universities to auto-fill semester dates.")
                    GuideBullet(icon: "slider.horizontal.3", text: "Manual Setup: Define your own semester start/end dates if your school isn't listed.")
                    GuideBullet(icon: "arrow.triangle.2.circlepath", text: "Switching Calendars: You can save multiple academic calendars (e.g., Year 1, Year 2) and switch between them in the Calendar tab.")
                }
                
                // MARK: - 3. Subjects & Grades
                GuideSectionCard(
                    title: "Subjects & Grades",
                    icon: "book.fill",
                    color: .green
                ) {
                    Text("Track every detail of your courses.")
                    
                    GuideBullet(icon: "doc.text.fill", text: "Course vs. Seminar: Track teachers, rooms, and schedules separately for lectures and seminars.")
                    GuideBullet(icon: "chart.bar.fill", text: "Grading: Log your grades (1-10 scale). The app automatically calculates your average.")
                    GuideBullet(icon: "person.fill.checkmark", text: "Attendance: Mark yourself 'Present' or 'Absent' to track your attendance rate.")
                }
                
                // MARK: - 4. Tasks
                GuideSectionCard(
                    title: "Tasks",
                    icon: "checklist",
                    color: .orange
                ) {
                    Text("Stay on top of assignments.")
                    
                    GuideBullet(icon: "exclamationmark.circle.fill", text: "Priorities: Set Low, Medium, or High priority to color-code your tasks.")
                    GuideBullet(icon: "flag.fill", text: "Flagging: Flag important tasks to keep them at the top of your list.")
                    GuideBullet(icon: "bell.fill", text: "Reminders: Set notifications from 5 minutes up to 1 week before the due date.")
                }
            }
            .padding(.vertical)
        }
        .background(Color.themeBackground)
        .navigationTitle("App Guide")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Helper Components

struct GuideSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 32)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                content
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct GuideBullet: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 20, height: 20)
                .background(Color.primary.opacity(0.1))
                .clipShape(Circle())
                .padding(.top, 2)
            
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}
