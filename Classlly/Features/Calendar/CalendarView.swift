import SwiftUI
import SwiftData

struct CalendarView: View {
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                RainbowCalendarView()
            case .arcade:
                ArcadeCalendarView()
            case .none:
                StandardCalendarView()
            }
        }
    }
}

// MARK: - 🌈 RAINBOW CALENDAR
struct RainbowCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var subjects: [Subject]
    @EnvironmentObject var themeManager: AppTheme
    
    @State private var selectedDate = Date()
    @State private var selectedDayIndex: Int = Calendar.current.component(.weekday, from: Date())
    
    // Logic Helpers
    private var startOfWeek: Date { Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? Date() }
    private var monthYearString: String { selectedDate.formatted(.dateTime.month(.wide).year()) }
    
    var body: some View {
        // Retrieve the user's selected accent color
        let accent = themeManager.selectedTheme.primaryColor
        
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // 1. Header & Navigation
                    HStack {
                        Button(action: { changeWeek(by: -1) }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                        
                        Text(monthYearString.uppercased())
                            .font(.title3)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                        
                        Button(action: { changeWeek(by: 1) }) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // 2. Rainbow Week Strip (Pass accent)
                    RainbowWeekStrip(selectedDate: $selectedDate, accentColor: accent)
                    
                    // 3. Schedule List
                    ScrollView {
                        VStack(spacing: 20) {
                            let classes = todaysClasses
                            
                            if classes.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "moon.stars.fill")
                                        .font(.system(size: 60))
                                        // Dynamic Gradient based on Accent
                                        .foregroundStyle(LinearGradient(
                                            colors: [accent, accent.opacity(0.5)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ))
                                        .padding(.top, 40)
                                    
                                    Text("NO CLASSES")
                                        .font(.headline)
                                        .fontWeight(.black)
                                        .foregroundColor(.gray)
                                }
                            } else {
                                ForEach(classes) { item in
                                    RainbowClassCard(item: item, accentColor: accent)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Today") {
                        withAnimation { selectedDate = Date() }
                    }
                }
            }
        }
    }
    
    // Logic
    private func changeWeek(by weeks: Int) {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: selectedDate) {
            withAnimation { selectedDate = newDate }
        }
    }
    
    struct ClassItem: Identifiable {
        let id = UUID()
        let subject: Subject
        let isSeminar: Bool
        var startTime: Date { isSeminar ? subject.seminarStartTime : subject.courseStartTime }
        var endTime: Date { isSeminar ? subject.seminarEndTime : subject.courseEndTime }
    }
    
    var todaysClasses: [ClassItem] {
        var items: [ClassItem] = []
        let weekday = Calendar.current.component(.weekday, from: selectedDate)
        
        for subject in subjects {
            if subject.courseDays.contains(weekday), subject.occursThisWeek(date: selectedDate, isSeminar: false) {
                items.append(ClassItem(subject: subject, isSeminar: false))
            }
            if subject.seminarDays.contains(weekday), subject.occursThisWeek(date: selectedDate, isSeminar: true) {
                items.append(ClassItem(subject: subject, isSeminar: true))
            }
        }
        return items.sorted { $0.startTime < $1.startTime }
    }
}

struct RainbowWeekStrip: View {
    @Binding var selectedDate: Date
    let accentColor: Color // ✅ Dynamic Accent
    
    private let calendar = Calendar.current
    private let weekDays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    
    var weekDates: [Date] {
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(weekDates, id: \.self) { date in
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let dayIndex = calendar.component(.weekday, from: date) - 1
                
                VStack(spacing: 6) {
                    Text(weekDays[dayIndex])
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isSelected ? .black : .gray)
                    
                    Text(date.formatted(.dateTime.day()))
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(isSelected ? .black : .white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    // ✅ Uses dynamic accent color for selection
                    isSelected ? AnyShapeStyle(accentColor) : AnyShapeStyle(Color(white: 0.1))
                )
                .cornerRadius(12)
                .onTapGesture { withAnimation { selectedDate = date } }
            }
        }
        .padding(.horizontal)
    }
}

struct RainbowClassCard: View {
    let item: RainbowCalendarView.ClassItem
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Time Column
            VStack(spacing: 2) {
                Text(item.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.caption).fontWeight(.bold).foregroundColor(.white)
                Rectangle().fill(Color.gray.opacity(0.3)).frame(width: 2, height: 20)
                Text(item.endTime.formatted(date: .omitted, time: .shortened))
                    .font(.caption).fontWeight(.bold).foregroundColor(.gray)
            }
            .frame(width: 60)
            
            // Card Content
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.subject.title)
                        .font(.headline)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                    
                    HStack {
                        // Badge uses Accent Color mixed with subject info
                        Text(item.isSeminar ? "SEMINAR" : "COURSE")
                            .font(.system(size: 8, weight: .bold))
                            .padding(4)
                            .background(accentColor.opacity(0.8)) // ✅ Dynamic Badge
                            .foregroundColor(.black)
                            .cornerRadius(4)
                        
                        Text(item.isSeminar ? item.subject.seminarClassroom : item.subject.courseClassroom)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                
                Image(systemName: item.isSeminar ? "person.2.fill" : "book.fill")
                    .font(.title)
                    .foregroundColor(item.subject.color)
                    .opacity(0.8)
            }
            .padding()
            .background(Color(white: 0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    // Highlighting stroke uses subject color (better for context),
                    // or could use accentColor if you prefer uniform look.
                    .stroke(item.subject.color.opacity(0.5), lineWidth: 1)
            )
        }
    }
}

// MARK: - 🏠 STANDARD CALENDAR (Preserved)
struct StandardCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var subjects: [Subject]
    
    @State private var selectedDate = Date()
    @State private var selectedDayIndex: Int = Calendar.current.component(.weekday, from: Date())
    
    private var monthYearString: String { selectedDate.formatted(.dateTime.month(.wide).year()) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { changeWeek(by: -1) }) { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                    Spacer()
                    Text(monthYearString).font(.headline)
                    Spacer()
                    Button(action: { changeWeek(by: 1) }) { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                }
                .padding(.horizontal).background(Color(.secondarySystemBackground))
                
                WeekStripView(selectedDate: $selectedDate, selectedDayIndex: $selectedDayIndex)
                    .padding(.bottom).background(Color(.secondarySystemBackground))
                
                ScrollView {
                    VStack(spacing: 16) {
                        if todaysClasses.isEmpty {
                            ContentUnavailableView("No Classes", systemImage: "calendar.badge.clock", description: Text("Free day!"))
                                .padding(.top, 40)
                        } else {
                            ForEach(todaysClasses) { item in
                                ClassCard(subject: item.subject, isSeminar: item.isSeminar)
                            }
                        }
                    }.padding()
                }
            }
            .navigationTitle("Schedule").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Today") { withAnimation { selectedDate = Date() } } } }
        }
    }
    
    private func changeWeek(by weeks: Int) {
        if let new = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: selectedDate) {
            withAnimation { selectedDate = new }
        }
    }
    
    struct ClassItem: Identifiable {
        let id = UUID(); let subject: Subject; let isSeminar: Bool
        var startTime: Date { isSeminar ? subject.seminarStartTime : subject.courseStartTime }
    }
    
    var todaysClasses: [ClassItem] {
        var items: [ClassItem] = []
        let weekday = Calendar.current.component(.weekday, from: selectedDate)
        for s in subjects {
            if s.courseDays.contains(weekday), s.occursThisWeek(date: selectedDate, isSeminar: false) { items.append(ClassItem(subject: s, isSeminar: false)) }
            if s.seminarDays.contains(weekday), s.occursThisWeek(date: selectedDate, isSeminar: true) { items.append(ClassItem(subject: s, isSeminar: true)) }
        }
        return items.sorted { $0.startTime < $1.startTime }
    }
}

// MARK: - STANDARD COMPONENTS
struct ClassCard: View {
    let subject: Subject; let isSeminar: Bool
    var body: some View {
        HStack(spacing: 0) {
            Rectangle().fill(subject.color).frame(width: 6)
            VStack(alignment: .leading, spacing: 4) {
                HStack { Text(subject.title).font(.headline); Spacer(); Text(timeString).font(.callout).monospacedDigit().foregroundStyle(.secondary) }
                HStack {
                    if isSeminar { Label("Seminar", systemImage: "person.2.fill").font(.caption).padding(4).background(Color.orange.opacity(0.1)).foregroundStyle(.orange).cornerRadius(4) }
                    Label(room, systemImage: "mappin.and.ellipse"); Spacer(); Label(teacher, systemImage: "person.fill")
                }.font(.caption).foregroundStyle(.secondary)
            }.padding()
        }.background(Color(.systemBackground)).cornerRadius(12).shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    var timeString: String { let s = isSeminar ? subject.seminarStartTime : subject.courseStartTime; let e = isSeminar ? subject.seminarEndTime : subject.courseEndTime; return "\(s.formatted(date: .omitted, time: .shortened)) - \(e.formatted(date: .omitted, time: .shortened))" }
    var room: String { isSeminar ? subject.seminarClassroom : subject.courseClassroom }
    var teacher: String { isSeminar ? subject.seminarTeacher : subject.courseTeacher }
}

struct WeekStripView: View {
    @Binding var selectedDate: Date; @Binding var selectedDayIndex: Int
    private let calendar = Calendar.current; private let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    var weekDates: [Date] { guard let start = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start else { return [] }; return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) } }
    var body: some View {
        HStack {
            ForEach(weekDates, id: \.self) { date in
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                VStack { Text(weekDays[calendar.component(.weekday, from: date)-1]).font(.caption2).fontWeight(.bold).foregroundStyle(isSelected ? .white : .secondary); Text(date.formatted(.dateTime.day())).font(.body).fontWeight(isSelected ? .bold : .regular).foregroundStyle(isSelected ? .white : .primary) }
                    .frame(maxWidth: .infinity).padding(.vertical, 8).background(isSelected ? Color.blue : Color.clear).clipShape(Capsule())
                    .onTapGesture { withAnimation { selectedDate = date } }
            }
        }.padding(.horizontal)
    }
}

// MARK: - 🕹️ ARCADE CALENDAR (Stub)
struct ArcadeCalendarView: View {
    var body: some View {
        ZStack { Color.black.ignoresSafeArea(); Text("Arcade Schedule").font(.system(.title, design: .monospaced)).foregroundColor(.cyan) }
    }
}
