import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var subjects: [Subject]
    
    @State private var selectedDate = Date()
    @State private var selectedDayIndex: Int = Calendar.current.component(.weekday, from: Date())
    
    // Helper to get the start of the current week for bi-weekly logic
    private var startOfWeek: Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? Date()
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Custom Week Strip
                WeekStripView(selectedDate: $selectedDate, selectedDayIndex: $selectedDayIndex)
                    .padding(.vertical)
                    .background(Color(.secondarySystemBackground))
                
                // Schedule List
                ScrollView {
                    VStack(spacing: 16) {
                        if todaysClasses.isEmpty {
                            ContentUnavailableView(
                                "No Classes",
                                systemImage: "calendar.badge.clock",
                                description: Text("You have a free day! Enjoy your time off.")
                            )
                            .padding(.top, 40)
                        } else {
                            ForEach(todaysClasses) { item in
                                ClassCard(subject: item.subject, isSeminar: item.isSeminar)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Today") {
                        let now = Date()
                        selectedDate = now
                        selectedDayIndex = Calendar.current.component(.weekday, from: now)
                    }
                }
            }
        }
    }
    
    // MARK: - Filtering Logic
    
    struct ClassItem: Identifiable {
        let id = UUID()
        let subject: Subject
        let isSeminar: Bool
        
        var startTime: Date {
            isSeminar ? subject.seminarStartTime : subject.courseStartTime
        }
    }
    
    var todaysClasses: [ClassItem] {
        var items: [ClassItem] = []
        
        // 1. Convert selectedDayIndex (Sunday=1) to Mon=1...Sun=7 if needed
        // Assuming your app uses Monday=1...Sunday=7 logic for the models
        // Swift Calendar: Sun=1, Mon=2... Sat=7
        let weekday = Calendar.current.component(.weekday, from: selectedDate)
        // Convert to Monday=1 standard
        let dayModelIndex = weekday == 1 ? 7 : weekday - 1
        
        for subject in subjects {
            // Check Course
            // Logic: Is it active this week? AND Is it active today?
            if subject.occursThisWeek(date: selectedDate, isSeminar: false) &&
               subject.occursOnDay(day: dayModelIndex, isSeminar: false) {
                items.append(ClassItem(subject: subject, isSeminar: false))
            }
            
            // Check Seminar
            if subject.hasSeminar {
                if subject.occursThisWeek(date: selectedDate, isSeminar: true) &&
                   subject.occursOnDay(day: dayModelIndex, isSeminar: true) {
                    items.append(ClassItem(subject: subject, isSeminar: true))
                }
            }
        }
        
        return items.sorted { $0.startTime < $1.startTime }
    }
}

// MARK: - Subviews

struct ClassCard: View {
    let subject: Subject
    let isSeminar: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Color strip
            Rectangle()
                .fill(subject.color)
                .frame(width: 6)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(subject.title)
                        .font(.headline)
                    Spacer()
                    Text(timeString)
                        .font(.callout)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    if isSeminar {
                        Label("Seminar", systemImage: "person.2.fill")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .foregroundStyle(.orange)
                            .cornerRadius(4)
                    }
                    
                    Label(room, systemImage: "mappin.and.ellipse")
                    Spacer()
                    Label(teacher, systemImage: "person.fill")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    var timeString: String {
        let start = isSeminar ? subject.seminarStartTime : subject.courseStartTime
        let end = isSeminar ? subject.seminarEndTime : subject.courseEndTime
        return "\(start.formatted(date: .omitted, time: .shortened)) - \(end.formatted(date: .omitted, time: .shortened))"
    }
    
    var room: String {
        isSeminar ? subject.seminarClassroom : subject.courseClassroom
    }
    
    var teacher: String {
        isSeminar ? subject.seminarTeacher : subject.courseTeacher
    }
}

struct WeekStripView: View {
    @Binding var selectedDate: Date
    @Binding var selectedDayIndex: Int
    
    private let calendar = Calendar.current
    private let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var weekDates: [Date] {
        var dates: [Date] = []
        // Get start of current week
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start else { return [] }
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                dates.append(date)
            }
        }
        return dates
    }
    
    var body: some View {
        HStack {
            ForEach(weekDates, id: \.self) { date in
                let dayIndex = calendar.component(.weekday, from: date)
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                
                VStack {
                    Text(weekDays[dayIndex - 1])
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(isSelected ? .white : .secondary)
                    
                    Text(date.formatted(.dateTime.day()))
                        .font(.body)
                        .fontWeight(isSelected ? .bold : .regular)
                        .foregroundStyle(isSelected ? .white : .primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.clear)
                .clipShape(Capsule())
                .onTapGesture {
                    withAnimation {
                        selectedDate = date
                        selectedDayIndex = dayIndex
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}
